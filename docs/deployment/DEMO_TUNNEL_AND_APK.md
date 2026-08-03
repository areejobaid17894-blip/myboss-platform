# Cloudflare tunnel, Error 1033, and external Android APK

**Audience:** DevOps, QA, mobile testers  
**Purpose:** Expose the demo outside your laptop, avoid Error 1033, and build an APK that works on mobile data.

---

## When to use what

| Access method | Best for | URL example |
|---------------|----------|-------------|
| **localhost** | Developer on same machine | `http://127.0.0.1:8090/app/` |
| **LAN (same Wi‑Fi)** | Team in same office / home Wi‑Fi | `http://192.168.x.x:8090/app/` |
| **Cloudflare quick tunnel** | Testers on mobile data / remote | `https://xxxx.trycloudflare.com/app/` |
| **External APK** | Android install without browser | App probes tunnel + LAN at startup |

Production will use **Orange Apigee**, not Cloudflare or nginx — see [`../architecture/APIGEE_VS_NGINX.md`](../architecture/APIGEE_VS_NGINX.md).

---

## Prerequisites

1. Demo stack running on `:8090`:

```bash
cd myboss-platform
./scripts/deploy-demo-server.sh 127.0.0.1
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
curl -sf http://127.0.0.1:8090/health   # must return OK
```

2. **cloudflared** installed: `brew install cloudflared`

---

## Start public tunnel

```bash
cd myboss-platform
./scripts/start-demo-tunnel.sh
```

Output:

- Public URL written to **`demo-public-url.txt`** (gitignored)
- Logs in **`demo-tunnel.log`**

Share with testers:

| App | URL |
|-----|-----|
| Mobile web | `https://<url>/app/` |
| Admin | `https://<url>/login` |
| Health | `https://<url>/health` |

### Keep tunnel alive

Quick tunnels **stop when `cloudflared` exits**. You must:

- Keep the **Mac awake** (disable sleep during demos)
- Do not kill the tunnel process
- If using Cursor/CI, run tunnel in **Terminal.app** or a persistent `tmux` session:

```bash
cd ~/Desktop/myboss-repos/myboss-platform
cloudflared tunnel --url http://127.0.0.1:8090 --no-autoupdate
```

**Important:** Each restart generates a **new URL**. Old links never work again.

---

## Error 1033 — Cloudflare Tunnel error

### What it means

**Error 1033** = Cloudflare has a DNS name for the tunnel, but **no active `cloudflared` connector** is running on your machine to serve traffic.

This is **not** a bug in the mobile or admin app. The backend on your laptop may still work locally.

### Symptoms

- Browser shows “Cloudflare Tunnel error” / Error 1033
- `curl https://old-url.trycloudflare.com/health` → **530**
- Local `curl http://127.0.0.1:8090/health` → **OK**

### Fix

1. Verify gateway locally:

```bash
curl http://127.0.0.1:8090/health
```

2. Restart tunnel:

```bash
cd myboss-platform
./scripts/start-demo-tunnel.sh
```

3. Use the **new** URL from `demo-public-url.txt` — old URLs are dead.

4. If APK was built with an old tunnel host, **rebuild the external APK** (see below).

### Check tunnel is running

```bash
pgrep -fl cloudflared
curl -sf "$(cat demo-public-url.txt)/health"
```

---

## External Android APK (mobile data / outside laptop)

APKs are **not stored in git** (`build/` is gitignored). Build locally and share by email, Drive, etc.

### Build (recommended script)

From **`myboss-mobile`**:

```bash
# Ensure tunnel URL is current:
cat ../myboss-platform/demo-public-url.txt

./build-external-android.sh
```

Output:

```
myboss-mobile/build/android-dist/myboss-demo-external.apk
```

This APK:

- Probes **Cloudflare tunnel first** (HTTPS)
- Falls back to **LAN IP** on same Wi‑Fi
- Enables **DEMO_MODE** (OTP auto-fill)

### Manual build (equivalent)

```bash
cd myboss-mobile
TUNNEL_URL=$(tr -d '[:space:]' < ../myboss-platform/demo-public-url.txt)
TUNNEL_HOST="${TUNNEL_URL#https://}"
fvm flutter build apk --release \
  --dart-define=API_HOSTS="${TUNNEL_HOST}" \
  --dart-define=GATEWAY_ORIGIN="${TUNNEL_URL}" \
  --dart-define=DEMO_MODE=true
```

### Install on phone

1. Uninstall any previous my boss app  
2. Copy APK to phone (email, WhatsApp, AirDrop, USB)  
3. Allow “install from unknown sources”  
4. Open APK → Install  
5. Login: `demo@orange.com` → OTP → accept Terms  

### Requirements for APK to work remotely

| Requirement | Why |
|-------------|-----|
| Demo stack running on laptop/VM | Backend services must be up |
| `cloudflared` running | Tunnel must be active |
| Mac/server **awake** | Tunnel runs from your machine |
| APK built with **current** tunnel URL | Old tunnel host is baked into APK |

If login fails after days: tunnel URL changed → rebuild APK.

---

## Troubleshooting matrix

| Problem | Likely cause | Fix |
|---------|--------------|-----|
| Error 1033 | Tunnel dead | Restart `./scripts/start-demo-tunnel.sh` |
| `/app/` 500 locally | nginx path misconfig | Re-run `ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh` |
| APK works on Wi‑Fi only | Built without tunnel URL | `./build-external-android.sh` after tunnel up |
| Admin 405 / login fails | Using `:8081` instead of gateway | Use `:8090/login` |
| OTP never arrives | Not demo mode / wrong API host | Rebuild with `DEMO_MODE=true` |

---

## Reset demo data before team testing

```bash
cd myboss-platform
./scripts/reset-demo-data.sh
```

Restores seed users, squads, and terms-not-accepted state.

---

## Related docs

| Doc | Topic |
|-----|-------|
| [`../architecture/APIGEE_VS_NGINX.md`](../architecture/APIGEE_VS_NGINX.md) | Demo nginx vs production Apigee |
| [`../devops/DEVOPS.md`](../devops/DEVOPS.md) | Full stack deploy |
| [`../../myboss-mobile/README.md`](../../myboss-mobile/README.md) | Flutter + APK |
| [`../deployment/pdf/03_APIGEE_CONNECTION.md`](pdf/03_APIGEE_CONNECTION.md) | Apigee proxy setup |

---

*Orange — my boss app*
