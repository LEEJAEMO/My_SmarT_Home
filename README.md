# Home Assistant deployment branch

This branch mirrors the files that may be pulled directly into Home Assistant /config.

- Real secrets are intentionally not tracked. The Git pull app restores /config/secrets.yaml after the first clone.
- Use git_command: pull and auto_restart: false while the setup is still changing.
- Validate with ha core check before restarting.
- Do not edit generated/runtime state under .storage in Git.

## Verified Comfee fan mapping

- SwitchBot remote type: `Others`
- `commandType`: `customize`
- Buttons: `POWER`, `Fan Speed 3`, `Timer`, `Mute`
- Home Assistant actions: `fan_power`, `fan_speed_cycle`, `fan_timer_cycle`, `fan_mute_toggle`
- Keep the real remote `deviceId` only in `/config/secrets.yaml`; never commit it.
- Treat power, speed, timer, and mute as toggle/cycle actions. Do not infer target state or retry automatically.
