"""Allow-list-only SwitchBot IR command service for Home Assistant.

The component deliberately accepts an allow-list key instead of raw device IDs or
commands. This keeps secrets and arbitrary OpenAPI access away from Assist/LLMs.
"""

from __future__ import annotations

import asyncio
import base64
import hashlib
import hmac
import logging
import time
import uuid
from typing import Any

import voluptuous as vol

from homeassistant.core import HomeAssistant, ServiceCall
from homeassistant.exceptions import HomeAssistantError
from homeassistant.helpers import config_validation as cv
from homeassistant.helpers.aiohttp_client import async_get_clientsession

DOMAIN = "switchbot_ir_allowlist"
SERVICE_SEND = "send"

CONF_TOKEN = "token"
CONF_SECRET = "secret"
CONF_COMMANDS = "commands"
CONF_DEVICE_ID = "device_id"
CONF_COMMAND = "command"
CONF_PARAMETER = "parameter"
CONF_COMMAND_TYPE = "command_type"
CONF_MIN_GAP_SECONDS = "min_gap_seconds"

API_BASE = "https://api.switch-bot.com/v1.1"

_LOGGER = logging.getLogger(__name__)

COMMAND_SCHEMA = vol.Schema(
    {
        vol.Required(CONF_DEVICE_ID): cv.string,
        vol.Required(CONF_COMMAND): cv.string,
        vol.Optional(CONF_PARAMETER, default="default"): cv.string,
        vol.Optional(CONF_COMMAND_TYPE, default="command"): vol.In(
            ["command", "customize"]
        ),
    }
)

CONFIG_SCHEMA = vol.Schema(
    {
        vol.Required(DOMAIN): vol.Schema(
            {
                vol.Required(CONF_TOKEN): cv.string,
                vol.Required(CONF_SECRET): cv.string,
                vol.Required(CONF_COMMANDS): {cv.string: COMMAND_SCHEMA},
                vol.Optional(CONF_MIN_GAP_SECONDS, default=2.0): vol.All(
                    vol.Coerce(float), vol.Range(min=2.0, max=30.0)
                ),
            }
        )
    },
    extra=vol.ALLOW_EXTRA,
)

SERVICE_SCHEMA = vol.Schema({vol.Required("action"): cv.string})


async def async_setup(hass: HomeAssistant, config: dict[str, Any]) -> bool:
    """Register the allow-listed SwitchBot IR service."""
    domain_config = config[DOMAIN]
    token: str = domain_config[CONF_TOKEN]
    secret: str = domain_config[CONF_SECRET]
    commands: dict[str, dict[str, str]] = domain_config[CONF_COMMANDS]
    min_gap: float = domain_config[CONF_MIN_GAP_SECONDS]

    session = async_get_clientsession(hass)
    send_lock = asyncio.Lock()
    last_sent_monotonic = 0.0

    async def _send(call: ServiceCall) -> None:
        nonlocal last_sent_monotonic

        action_name: str = call.data["action"]
        if action_name not in commands:
            allowed = ", ".join(sorted(commands))
            raise HomeAssistantError(
                f"허용되지 않은 SwitchBot IR 명령입니다: {action_name}. "
                f"허용 목록: {allowed}"
            )

        selected = commands[action_name]
        timestamp = str(int(time.time() * 1000))
        nonce = str(uuid.uuid4())
        string_to_sign = f"{token}{timestamp}{nonce}"
        signature = base64.b64encode(
            hmac.new(
                secret.encode("utf-8"),
                string_to_sign.encode("utf-8"),
                hashlib.sha256,
            ).digest()
        ).decode("utf-8")

        headers = {
            "Authorization": token,
            "Content-Type": "application/json; charset=utf8",
            "sign": signature,
            "nonce": nonce,
            "t": timestamp,
        }
        payload = {
            "command": selected[CONF_COMMAND],
            "parameter": selected[CONF_PARAMETER],
            "commandType": selected[CONF_COMMAND_TYPE],
        }
        url = f"{API_BASE}/devices/{selected[CONF_DEVICE_ID]}/commands"

        # One global lock enforces line-of-sight IR pacing. Do not retry: repeating
        # a toggle command could undo the first successful command.
        async with send_lock:
            remaining = min_gap - (time.monotonic() - last_sent_monotonic)
            if remaining > 0:
                await asyncio.sleep(remaining)

            try:
                async with session.post(
                    url, headers=headers, json=payload, timeout=15
                ) as response:
                    body = await response.json(content_type=None)
            except (TimeoutError, asyncio.TimeoutError) as err:
                raise HomeAssistantError(
                    f"SwitchBot IR 명령 시간이 초과되었습니다: {action_name}"
                ) from err
            except Exception as err:  # Home Assistant records the original cause.
                raise HomeAssistantError(
                    f"SwitchBot IR 명령 전송에 실패했습니다: {action_name}"
                ) from err
            finally:
                last_sent_monotonic = time.monotonic()

        if response.status < 200 or response.status >= 300:
            raise HomeAssistantError(
                f"SwitchBot API HTTP 오류 {response.status}: {action_name}"
            )
        if not isinstance(body, dict) or body.get("statusCode") != 100:
            status_code = body.get("statusCode", "unknown") if isinstance(body, dict) else "invalid"
            message = body.get("message", "invalid response") if isinstance(body, dict) else "invalid response"
            raise HomeAssistantError(
                f"SwitchBot API 오류 {status_code} ({message}): {action_name}"
            )

        _LOGGER.info("SwitchBot IR allow-list command sent: %s", action_name)
        hass.bus.async_fire(
            f"{DOMAIN}_command_sent", {"action": action_name}
        )

    hass.services.async_register(
        DOMAIN,
        SERVICE_SEND,
        _send,
        schema=SERVICE_SCHEMA,
    )
    return True

