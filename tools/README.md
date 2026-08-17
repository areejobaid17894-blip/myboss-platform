# Local tools (not in git)

This folder holds binaries used on a developer laptop only. They are **gitignored** — only this README is tracked.

## cloudflared (optional — public demo tunnels)

Used to expose local `:3001` / `:8081` to testers without publishing ports on the LAN.

1. Download **cloudflared** for your OS: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/
2. On Windows, place the binary here as `cloudflared.exe`.
3. Start a quick tunnel, e.g. `.\cloudflared.exe tunnel --url http://127.0.0.1:3001`
4. Copy the `*.trycloudflare.com` host into `demo-public-url.txt` (gitignored) or rebuild admin/APK with that host.

Do **not** commit `cloudflared.exe` or other binaries to git.
