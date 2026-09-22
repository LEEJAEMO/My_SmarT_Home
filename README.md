# Home Assistant deployment branch

This branch mirrors the files that may be pulled directly into Home Assistant /config.

- Real secrets are intentionally not tracked. The Git pull app restores /config/secrets.yaml after the first clone.
- Use git_command: pull and auto_restart: false while the setup is still changing.
- Validate with ha core check before restarting.
- Do not edit generated/runtime state under .storage in Git.
