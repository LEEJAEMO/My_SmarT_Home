"""Verified allow-list router for existing HA panels and optional SwitchBot IR."""
from __future__ import annotations
import asyncio
import base64
import hashlib
import hmac
import time
import uuid
from typing import Any
import voluptuous as vol
from homeassistant.core import HomeAssistant, ServiceCall
from homeassistant.exceptions import HomeAssistantError
from homeassistant.helpers import config_validation as cv
from homeassistant.helpers.aiohttp_client import async_get_clientsession

DOMAIN = "switchbot_ir_allowlist"
API_BASE = "https://api.switch-bot.com/v1.1"
NATIVE_SERVICES = ("switch.turn_on", "switch.turn_off", "button.press",
                   "climate.turn_on", "climate.turn_off", "fan.turn_on", "fan.turn_off")
IR_SCHEMA = vol.Schema({
    vol.Optional("verified", default=False): cv.boolean,
    vol.Optional("backend", default="ir"): vol.In(["ir"]),
    vol.Required("device_id"): cv.string,
    vol.Required("command"): cv.string,
    vol.Optional("parameter", default="default"): cv.string,
    vol.Optional("command_type", default="command"): vol.In(["command", "customize"]),
})
NATIVE_SCHEMA = vol.Schema({
    vol.Optional("verified", default=False): cv.boolean,
    vol.Required("backend"): vol.In(["ha"]),
    vol.Required("service"): vol.In(NATIVE_SERVICES),
    vol.Required("entity_id"): cv.entity_id,
})


def validate_command(value: dict) -> dict:
    if value.get("backend") == "ha":
        result = NATIVE_SCHEMA(value)
        if result["entity_id"].split(".")[0] != result["service"].split(".")[0]:
            raise vol.Invalid("Native entity and service domains must match")
        return result
    return IR_SCHEMA(value)


CONFIG_SCHEMA = vol.Schema({
    vol.Required(DOMAIN): vol.Schema({
        vol.Optional("token", default=""): cv.string,
        vol.Optional("secret", default=""): cv.string,
        vol.Required("commands"): {cv.string: validate_command},
        vol.Optional("min_gap_seconds", default=2.0):
            vol.All(vol.Coerce(float), vol.Range(min=2.0, max=30.0)),
    })
}, extra=vol.ALLOW_EXTRA)
SERVICE_SCHEMA = vol.Schema({vol.Required("action"): cv.string})


async def async_setup(hass: HomeAssistant, config: dict[str, Any]) -> bool:
    settings = config[DOMAIN]
    commands = settings["commands"]
    gap = settings["min_gap_seconds"]
    lock = asyncio.Lock()
    pending: set[str] = set()
    finished: dict[str, float] = {}
    last_finished = float("-inf")
    session = async_get_clientsession(hass)
    attrs = {
        "friendly_name": "명령 전달 상태 (물리 상태 아님)",
        "verified_actions": sorted(k for k, v in commands.items() if v["verified"]),
        "last_action": "", "last_request_at": None, "physical_result": "unknown",
    }

    def status(value: str, action: str = "") -> None:
        attrs["last_action"] = action
        if value == "sending":
            attrs["last_request_at"] = time.time()
        hass.states.async_set(f"{DOMAIN}.status", value, dict(attrs))

    status("idle")

    async def send(call: ServiceCall) -> None:
        nonlocal last_finished
        key = call.data["action"]
        selected = commands.get(key)
        if not selected or not selected["verified"]:
            raise HomeAssistantError("미검증 또는 허용되지 않은 동작입니다.")
        if key in pending or time.monotonic() - finished.get(key, float("-inf")) < gap:
            raise HomeAssistantError("중복 입력을 차단했습니다. 자동 재시도하지 마세요.")
        pending.add(key)
        try:
            async with lock:
                remaining = gap - (time.monotonic() - last_finished)
                if remaining > 0:
                    await asyncio.sleep(remaining)
                status("sending", key)
                try:
                    if selected["backend"] == "ha":
                        entity = hass.states.get(selected["entity_id"])
                        # IR switches may start unknown: it is no physical feedback.
                        # A verified manual press is still usable; unavailable is not.
                        if entity is None or entity.state == "unavailable":
                            raise HomeAssistantError("연결 대상이 없거나 사용할 수 없습니다.")
                        domain, service = selected["service"].split(".")
                        if not hass.services.has_service(domain, service):
                            raise HomeAssistantError("확인된 HA action이 현재 없습니다.")
                        async with asyncio.timeout(15):
                            await hass.services.async_call(
                                domain, service, {"entity_id": selected["entity_id"]},
                                blocking=True, context=call.context,
                            )
                    else:
                        token, secret = settings["token"], settings["secret"]
                        if not token or not secret or token.startswith("PASTE_") or secret.startswith("PASTE_"):
                            raise HomeAssistantError("SwitchBot 인증 설정이 필요합니다.")
                        # Sign after pacing, never reuse a queued/stale signature.
                        timestamp, nonce = str(int(time.time() * 1000)), str(uuid.uuid4())
                        signature = base64.b64encode(hmac.new(
                            secret.encode(), f"{token}{timestamp}{nonce}".encode(),
                            hashlib.sha256).digest()).decode()
                        async with session.post(
                            f"{API_BASE}/devices/{selected['device_id']}/commands",
                            headers={"Authorization": token, "Content-Type": "application/json",
                                     "sign": signature, "nonce": nonce, "t": timestamp},
                            json={"command": selected["command"], "parameter": selected["parameter"],
                                  "commandType": selected["command_type"]}, timeout=15,
                        ) as response:
                            body = await response.json(content_type=None)
                            if not 200 <= response.status < 300:
                                raise HomeAssistantError("SwitchBot HTTP 오류")
                            if not isinstance(body, dict) or body.get("statusCode") != 100:
                                raise HomeAssistantError("SwitchBot 명령 거절")
                    status("request_accepted", key)
                    hass.bus.async_fire(f"{DOMAIN}_command_sent", {"action": key})
                except asyncio.CancelledError:
                    status("result_unknown", key)
                    raise
                except Exception:
                    status("result_unknown", key)
                    # No upstream payload, credential or device ID in user errors.
                    raise HomeAssistantError(
                        "명령 결과 미확인. 실물을 확인하세요. 자동 재시도 없음."
                    ) from None
                finally:
                    last_finished = time.monotonic()
                    finished[key] = last_finished
        finally:
            pending.discard(key)

    hass.services.async_register(DOMAIN, "send", send, schema=SERVICE_SCHEMA)
    return True
