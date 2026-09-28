# Repository instructions

This repository contains a personal smart-home deployment for a Galaxy Book6 Pro running Home Assistant OS in VirtualBox. The controlled devices include SwitchBot Curtain, Meter Pro CO2, an older SwitchBot Hub Mini, and IR-only Daikin, Comfee, lighting, and projector appliances.

## PKM bootstrap

- Read `PKM/llms.md` before broad repository discovery. It contains the compact current baseline and routes each task to the minimum required context.
- Read only the relevant files under `PKM/Specs/`, `PKM/Modules/`, and `PKM/Troubleshooting/` before changing behavior.
- After a material change, update the applicable Spec and add or update a dated entry under `PKM/Logs/`.
- Treat PKM logs as historical evidence, not live runtime state. Re-run read-only diagnostics when current status matters.

## Working rules

- Never commit real SwitchBot tokens, secrets, OpenAI API keys, Home Assistant access tokens, device IDs, `.storage` contents, databases, backups, or VM disk images.
- Keep `home-assistant/secrets.yaml.example` as placeholders only. Real values belong in `/config/secrets.yaml` on the Home Assistant instance.
- Do not expose `switchbot_ir_allowlist.send`, raw OpenAPI commands, credentials, or configuration helpers to Assist or an LLM.
- No discrete air-conditioner presets or definite OFF are currently verified. The two observed DIY panels are a power toggle and mode/timer cycles. Do not enable absolute cooling, heating, dehumidify, or OFF without a newly learned and physically verified discrete command.
- Keep at least two seconds between IR commands and do not automatically retry toggle commands.
- The Comfee fan is an `Others` IR remote with `command_type: customize` and exact buttons `POWER`, `Fan Speed 3`, `Timer`, `Mute`. Keep the corresponding `fan_power`, `fan_speed_cycle`, `fan_timer_cycle`, `fan_mute_toggle` actions stateless; no target-state automation or retry.
- Never commit the real fan remote device ID; keep it only in `/config/secrets.yaml`.
- Never power-cut the projector. Use its normal remote shutdown so the cooling fan can finish.
- Preserve the assumed-state guards for a toggle-only projector remote. Do not infer the fan's state from a button command.
- Treat SmartThings and the SwitchBot app as fallback paths; Home Assistant is the primary automation layer.
- Keep the independent SwitchBot CO2 alerts because Home Assistant may be unavailable while the laptop is off.

## Repository layout

- `setup/`: Windows host, VirtualBox, HAOS, validation, and SwitchBot discovery scripts
- `home-assistant/packages/`: scenes, scripts, helpers, and automations
- `home-assistant/custom_components/switchbot_ir_allowlist/`: allow-list-only SwitchBot OpenAPI service
- `home-assistant/custom_sentences/ko/`: deterministic Korean commands
- `home-assistant/dashboards/`: dashboard YAML
- `CHECKLIST.md`: physical setup and verification checklist
- `docs/`: user-facing setup and operations manual mirrored from the Obsidian vault
- `DEPLOYMENT_STATUS.md`: last verified deployment state
- `PKM/`: token-efficient agent context, specifications, reusable modules, troubleshooting records, and work logs

## Required checks before committing

1. Parse every PowerShell file with the Windows PowerShell parser.
2. Compile the custom component Python file.
3. Parse all YAML and JSON files.
4. Confirm every `switchbot_ir_allowlist.send` action is defined in the allow list.
5. Scan the complete diff for credentials and real device IDs.
6. Update `DEPLOYMENT_STATUS.md` only with facts that were actually verified.

Prefer a pull request for future behavioral changes. Explain changes to scenes, safety guards, exposure, thresholds, or IR state assumptions in the pull request body.
