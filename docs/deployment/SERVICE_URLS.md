# my boss app — Direct service URLs

Clients call **microservices directly** on ports **3001–3006**. There is no Apigee and no nginx API gateway.

---

## Service ports

| Service | Port | Base URL |
|---------|------|----------|
| auth-service | 3001 | `http://<HOST>:3001/api/v1` |
| user-service | 3002 | `http://<HOST>:3002/api/v1` |
| config-service | 3003 | `http://<HOST>:3003/api/v1` |
| squad-service | 3004 | `http://<HOST>:3004/api/v1` |
| survey-service | 3005 | `http://<HOST>:3005/api/v1` |
| notification-service | 3006 | `http://<HOST>:3006/api/v1` |

Replace `<HOST>` with:
- **`127.0.0.1`** — same machine as Docker
- **`10.x.x.x`** — LAN IP (phone / other device on same network)
- **`213.x.x.x`** — VM public IP (when firewall exposes ports)

---

## Deployed URL examples

If your demo server public IP is `213.139.63.204`:

| App | URL |
|-----|-----|
| Admin | `http://213.139.63.204:8081` |
| Auth API | `http://213.139.63.204:3001/api/v1` |
| Auth Swagger | `http://213.139.63.204:3001/api/v1/docs` |
| Sign-in | `POST http://213.139.63.204:3001/api/v1/auth/sign-in` |

Build admin for that host:

```bash
cd myboss-platform
DEMO_HOST=213.139.63.204 docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal
```

Build mobile APK:

```bash
cd myboss-mobile
SERVER_HOST=213.139.63.204 ./build-external-android.sh
```

---

## Admin portal

| Mode | Command | APIs baked in |
|------|---------|---------------|
| Docker | `ADMIN_BUILD_MODE=demo DEMO_HOST=<HOST>` | `http://<HOST>:3001/api/v1`, … |
| Vite dev | `npm run dev` | `http://localhost:3001/api/v1`, … |

---

## Mobile app

```bash
# Emulator (backend on same Mac)
fvm flutter run --dart-define=ENV=development --dart-define=DEMO_MODE=true

# Physical device / remote server
fvm flutter run --dart-define=API_HOST=213.139.63.204 --dart-define=ENV=demo --dart-define=DEMO_MODE=true

# Release APK
SERVER_HOST=213.139.63.204 ./build-external-android.sh
```

Android emulator uses `10.0.2.2` automatically when `ENV=development` and no `API_HOST` is set.

---

## Firewall (VM deploy)

Expose to clients that need access:

```bash
sudo ufw allow 8081/tcp    # admin SPA
sudo ufw allow 3001:3006/tcp   # APIs (restrict to office/VPN IP range in production)
```

---

*Orange — my boss app*
