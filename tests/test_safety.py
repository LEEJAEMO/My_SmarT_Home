"""Source and mocked-backend checks, NOT an HA runtime or browser simulation."""
import asyncio
import importlib.util
import re
import sys
import types
import unittest
from pathlib import Path
from unittest.mock import patch

import voluptuous as vol
import yaml

ROOT = Path(__file__).resolve().parents[1]


class HALoader(yaml.SafeLoader):
    pass


HALoader.add_multi_constructor('!', lambda loader, tag, node: loader.construct_scalar(node))


def read_yaml(path):
    return yaml.load((ROOT / path).read_text(encoding='utf-8'), Loader=HALoader)


def walk(value):
    if isinstance(value, dict):
        yield value
        for item in value.values():
            yield from walk(item)
    elif isinstance(value, list):
        for item in value:
            yield from walk(item)


class HAError(Exception):
    pass


def load_component():
    # Exact boundaries are stubs; voluptuous schemas and production handler are real.
    names = ['homeassistant', 'homeassistant.core', 'homeassistant.exceptions',
             'homeassistant.helpers', 'homeassistant.helpers.config_validation',
             'homeassistant.helpers.aiohttp_client']
    stubs = {name: types.ModuleType(name) for name in names}
    stubs['homeassistant.core'].HomeAssistant = object
    stubs['homeassistant.core'].ServiceCall = object
    stubs['homeassistant.exceptions'].HomeAssistantError = HAError
    cv = stubs['homeassistant.helpers.config_validation']
    cv.string = str
    cv.boolean = bool
    cv.entity_id = vol.Match(r'^[a-z_]+\.[a-z0-9_]+$')
    stubs['homeassistant.helpers.aiohttp_client'].async_get_clientsession = lambda hass: hass.session
    spec = importlib.util.spec_from_file_location('tested_component', ROOT / 'home-assistant/custom_components/switchbot_ir_allowlist/__init__.py')
    module = importlib.util.module_from_spec(spec)
    with patch.dict(sys.modules, stubs):
        spec.loader.exec_module(module)
    return module


COMPONENT = load_component()


class FakeStates:
    def __init__(self):
        self.values = {'switch.fixture': types.SimpleNamespace(state='off')}
        self.history = []

    def get(self, entity):
        return self.values.get(entity)

    def async_set(self, entity, state, attrs):
        self.values[entity] = types.SimpleNamespace(state=state, attributes=attrs)
        self.history.append((state, dict(attrs)))


class FakeServices:
    def __init__(self):
        self.calls = []
        self.error = None
        self.pause = None
        self.exists = True

    def has_service(self, domain, service):
        return self.exists

    def async_register(self, domain, name, handler, schema):
        self.handler = handler

    async def async_call(self, domain, name, data, **kwargs):
        self.calls.append((domain, name, data, kwargs))
        if self.pause:
            await self.pause.wait()
        if self.error:
            raise self.error


class FakeResponse:
    def __init__(self, session):
        self.session = session
        self.status = session.http_status

    async def __aenter__(self):
        if self.session.error:
            raise self.session.error
        return self

    async def __aexit__(self, *args):
        pass

    async def json(self, **kwargs):
        return self.session.body


class FakeSession:
    def __init__(self):
        self.calls = []
        self.error = None
        self.http_status = 200
        self.body = {'statusCode': 100}

    def post(self, url, **kwargs):
        self.calls.append((url, kwargs))
        return FakeResponse(self)


class BackendTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.events = []
        self.hass = types.SimpleNamespace(states=FakeStates(), services=FakeServices(),
            session=FakeSession(), bus=types.SimpleNamespace(async_fire=lambda *a: self.events.append(a)))
        self.native = {'backend': 'ha', 'service': 'switch.turn_on', 'entity_id': 'switch.fixture', 'verified': True}
        self.ir = {'device_id': 'FIXTURE_ONLY', 'command': 'POWER', 'verified': True}

    async def setup_handler(self, commands=None):
        settings = {'commands': commands or {'power': self.native}, 'token': 'fixture-token', 'secret': 'fixture-secret'}
        config = COMPONENT.CONFIG_SCHEMA({COMPONENT.DOMAIN: settings})
        await COMPONENT.async_setup(self.hass, config)

    async def send(self, key='power'):
        await self.hass.services.handler(types.SimpleNamespace(data={'action': key}, context='fixture-context'))

    async def test_native_exactly_once_and_no_http(self):
        await self.setup_handler()
        await self.send()
        self.assertEqual(len(self.hass.services.calls), 1)
        self.assertEqual(self.hass.services.calls[0][:3], ('switch', 'turn_on', {'entity_id': 'switch.fixture'}))
        self.assertEqual(self.hass.session.calls, [])
        self.assertEqual(self.hass.states.history[-1][0], 'request_accepted')
        self.assertEqual(self.hass.states.history[-1][1]['physical_result'], 'unknown')

    async def test_unverified_defaults_closed(self):
        command = dict(self.native)
        command.pop('verified')
        await self.setup_handler({'power': command})
        with self.assertRaises(HAError):
            await self.send()
        self.assertEqual(self.hass.services.calls, [])

    async def test_unknown_action_no_transport(self):
        await self.setup_handler()
        with self.assertRaises(HAError):
            await self.send('raw_command')
        self.assertEqual(self.hass.services.calls, [])

    async def test_unavailable_entity_no_transport(self):
        await self.setup_handler()
        self.hass.states.values['switch.fixture'].state = 'unavailable'
        with self.assertRaises(HAError):
            await self.send()
        self.assertEqual(self.hass.services.calls, [])

    async def test_unknown_ir_switch_can_take_one_verified_manual_press(self):
        await self.setup_handler()
        self.hass.states.values['switch.fixture'].state = 'unknown'
        await self.send()
        self.assertEqual(len(self.hass.services.calls), 1)
        self.assertEqual(self.hass.states.history[-1][1]['physical_result'], 'unknown')

    async def test_missing_service_no_transport(self):
        await self.setup_handler()
        self.hass.services.exists = False
        with self.assertRaises(HAError):
            await self.send()
        self.assertEqual(self.hass.services.calls, [])

    async def test_inflight_double_press_rejected(self):
        await self.setup_handler()
        self.hass.services.pause = asyncio.Event()
        first = asyncio.create_task(self.send())
        await asyncio.sleep(0)
        with self.assertRaises(HAError):
            await self.send()
        self.hass.services.pause.set()
        await first
        self.assertEqual(len(self.hass.services.calls), 1)

    async def test_completed_double_press_rejected(self):
        await self.setup_handler()
        await self.send()
        with self.assertRaises(HAError):
            await self.send()
        self.assertEqual(len(self.hass.services.calls), 1)

    async def test_timeout_is_unknown_no_retry(self):
        await self.setup_handler()
        self.hass.services.error = TimeoutError('fixture')
        with self.assertRaises(HAError):
            await self.send()
        self.assertEqual(len(self.hass.services.calls), 1)
        self.assertEqual(self.hass.states.history[-1][0], 'result_unknown')
        self.assertEqual(self.events, [])

    async def test_cancel_is_unknown_no_retry(self):
        await self.setup_handler()
        self.hass.services.pause = asyncio.Event()
        task = asyncio.create_task(self.send())
        await asyncio.sleep(0)
        task.cancel()
        with self.assertRaises(asyncio.CancelledError):
            await task
        self.assertEqual(len(self.hass.services.calls), 1)
        self.assertEqual(self.hass.states.history[-1][0], 'result_unknown')

    async def test_ir_payload_exactly_once(self):
        await self.setup_handler({'power': self.ir})
        await self.send()
        self.assertEqual(len(self.hass.session.calls), 1)
        self.assertEqual(self.hass.session.calls[0][1]['json'], {'command': 'POWER', 'commandType': 'command', 'parameter': 'default'})

    async def test_ir_errors_do_not_leak_or_retry(self):
        for status, body, error in [(503, {}, None), (200, {'statusCode': 190, 'message': 'PRIVATE_PAYLOAD'}, None), (200, [], None), (200, {}, TimeoutError())]:
            with self.subTest(status=status, body=body):
                self.hass.session = FakeSession()
                self.hass.session.http_status, self.hass.session.body, self.hass.session.error = status, body, error
                await self.setup_handler({'power': self.ir})
                with self.assertRaises(HAError) as caught:
                    await self.send()
                self.assertNotIn('PRIVATE_PAYLOAD', str(caught.exception))
                self.assertEqual(len(self.hass.session.calls), 1)

    async def test_global_gap_between_different_actions(self):
        await self.setup_handler({'power': self.native, 'mode': self.native})
        clock = types.SimpleNamespace(value=100.0)
        sleeps = []

        async def sleep(delay):
            sleeps.append(delay)
            clock.value += delay

        with patch.object(COMPONENT, 'time', types.SimpleNamespace(monotonic=lambda: clock.value, time=lambda: clock.value)), patch.object(COMPONENT.asyncio, 'sleep', sleep):
            await self.send('power')
            await self.send('mode')
        self.assertEqual(sleeps, [2.0])
        self.assertEqual(len(self.hass.services.calls), 2)


class SourceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.package = read_yaml('home-assistant/packages/smart_home.yaml')
        cls.config = read_yaml('home-assistant/configuration.yaml.example')
        cls.dashboard = read_yaml('home-assistant/dashboards/smart_home.yaml')

    def test_native_schema_rejects_raw_service_and_mismatched_target(self):
        for service, entity in [('script.turn_on', 'script.fixture'), ('switch.turn_on', 'light.fixture'), ('shell_command.run', 'shell_command.fixture')]:
            with self.assertRaises(vol.Invalid):
                COMPONENT.validate_command({'backend': 'ha', 'service': service, 'entity_id': entity})

    def test_service_schema_rejects_raw_payload(self):
        with self.assertRaises(vol.Invalid):
            COMPONENT.SERVICE_SCHEMA({'action': 'power', 'device_id': 'RAW'})

    def test_gap_cannot_be_less_than_two(self):
        with self.assertRaises(vol.Invalid):
            COMPONENT.CONFIG_SCHEMA({COMPONENT.DOMAIN: {'commands': {}, 'min_gap_seconds': 1}})

    def test_all_commands_closed_by_default(self):
        self.assertTrue(all(not v['verified'] for v in self.config[COMPONENT.DOMAIN]['commands'].values()))

    def test_allowlist_covers_every_call(self):
        used = {node['data']['action'] for node in walk(self.package) if node.get('action') == COMPONENT.DOMAIN + '.send'}
        self.assertTrue(used <= self.config[COMPONENT.DOMAIN]['commands'].keys())

    def test_old_ac_presets_are_fail_closed(self):
        for key in ('aircon_cool_26', 'aircon_heat_20', 'aircon_dry', 'aircon_off'):
            sequence = self.package['script'][key]['sequence']
            self.assertTrue(sequence[0]['error'])
            self.assertFalse(any('action' in n for n in walk(sequence)))

    def test_scenes_never_call_unverified_appliances(self):
        for key, script in self.package['script'].items():
            if key.startswith('scene_'):
                actions = [n.get('action', '') for n in walk(script)]
                self.assertFalse(any(re.match(r'script\.(aircon|fan|light|projector)', a) for a in actions), key)

    def test_voice_only_preparation_scenes(self):
        intents = self.package['intent_script']
        actions = [n.get('action', '') for n in walk(intents) if isinstance(n.get('action', ''), str)]
        self.assertFalse(any(re.match(r'script\.(aircon|fan|light|projector)', a) for a in actions))
        self.assertNotIn('action', intents['SmartHomeUnsupported'])

    def test_dashboard_no_toggle_or_unverified_appliance_buttons(self):
        self.assertFalse(any(n.get('action') == 'toggle' for n in walk(self.dashboard)))
        self.assertFalse(any(str(n.get('entity', '')).startswith(('script.light_', 'script.projector_', 'script.aircon_off')) for n in walk(self.dashboard)))

    def test_ventilation_resets_after_restart_and_needs_new_sample(self):
        self.assertIs(self.package['input_boolean']['ventilation_active']['initial'], False)
        automation = next(a for a in self.package['automation'] if a['id'] == 'smarthome_ventilation_complete')
        source = str(automation['condition'])
        self.assertIn('last_reported', source)
        self.assertIn('low + 600', source)
        self.assertIn('smarthome_ventilation_low', source)

    def test_projector_toggle_requires_reconfirmation_after_request(self):
        for key in ('projector_on', 'projector_off'):
            script = self.package['script'][key]
            choose = next(n for n in walk(script) if 'choose' in n)
            self.assertTrue(choose['default'][0]['error'])
            self.assertTrue(any(n.get('action') == 'input_boolean.turn_off'
                and n.get('target', {}).get('entity_id') == 'input_boolean.projector_state_known'
                for n in walk(script)))


if __name__ == '__main__':
    unittest.main(verbosity=2)
