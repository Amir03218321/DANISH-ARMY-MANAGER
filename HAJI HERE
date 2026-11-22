# DANISH ARMY TMP MANAGER — Upload Package 1.0.5

This is the existing manager package, not a new terminal app. It preserves the TMP manager, panel downloader, driver downloader, file preview, permission menu, confirmed deletion, script execution option, WhatsApp join gate, GitHub access request, update check, and improvement request.

## Upload
Upload every file in this folder to the ROOT of https://github.com/Amir03218321/FREE-FIRE-PANEL (branch `main`).

Files: `danish-army-manager.sh`, `install.sh`, `update.sh`, `uninstall.sh`, `approved-users.txt`, `VERSION`, `README.md`, `CHANGELOG.md`, `LICENSE`.
`access-request-worker.js` is the Worker source reference.

## Cloudflare
Configured Worker URL: https://sparkling-star-daab.hahatechnology251.workers.dev/
The shell script sends JSON `userId` and `appVersion`, matching the deployed Worker. Keep `GITHUB_TOKEN` only in Cloudflare Worker Secrets. The Worker creates Issues in `Amir03218321/DANIX-IMPROVEMENTS`.

## Approve users
Add a line to `approved-users.txt`: `USER_ID|EXPIRY_UNIX`.
Use `0` for no expiry; otherwise use a future Unix timestamp. Legacy one-ID lines are still accepted as no-expiry entries.

## Install in Termux
```bash
pkg update -y
pkg install -y curl git bash coreutils
curl -fsSL https://raw.githubusercontent.com/Amir03218321/FREE-FIRE-PANEL/main/install.sh -o install.sh
bash install.sh
danish-army-manager
```

TMP file operations require root authorization as in the original tool. Review scripts before execution; root execution can affect the whole device. Never upload GitHub tokens.
