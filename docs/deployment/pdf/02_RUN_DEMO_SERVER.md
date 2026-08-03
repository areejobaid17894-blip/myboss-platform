# my boss app — Run Demo Server (Docker)

**Audience:** DevOps, developers, QA

---

## 1. Full demo deploy (recommended)

From repo root:

```bash
cp .env.example .env
./infrastructure/scripts/deploy-demo-server.sh 127.0.0.1
ALLOW_DEPLOY=1 ./infrastructure/scripts/deploy-mobile-web.sh
./infrastructure/scripts/start-demo-tunnel.sh          # optional: public URL
./infrastructure/scripts/verify-mobile-api.sh 127.0.0.1 --gateway
./infrastructure/scripts/verify-localhost.sh
```

---

## 2. Docker compose reference

```bash
COMPOSE="docker compose -f infrastructure/docker/docker-compose.demo.yml"

$COMPOSE up -d --build
$COMPOSE --profile with-admin up -d --build admin-portal
$COMPOSE ps
$COMPOSE logs -f auth-service
$COMPOSE down
```

---

## 3. Published ports

| Container | Host port | URL |
|-----------|-----------|-----|
| API gateway | **8090** | http://HOST:8090/app/ (mobile web) |
| myboss-auth | 3001 | http://HOST:8090/auth/api/v1/docs |
| myboss-user | 3002 | http://HOST:8090/user/api/v1/docs |
| myboss-config | 3003 | http://HOST:8090/config/api/v1/docs (**Chat**) |
| myboss-squad | 3004 | http://HOST:8090/squad/api/v1/docs |
| myboss-survey | 3005 | http://HOST:8090/survey/api/v1/docs |
| myboss-admin | 8081 | http://HOST:8081 or via gateway `/login` |

---

## 4. Swagger documentation

All services expose OpenAPI at `/api/v1/docs` when `APP_ENV=demo` or `SWAGGER_ENABLED=true`.

**Chat endpoints** are documented under the **Chat** tag in config-service Swagger.

See [`docs/api/CHAT_API.md`](../../api/CHAT_API.md).

---

## 5. Demo login

| Role | Email | Notes |
|------|-------|-------|
| Employee | demo@orange.com | OTP in sign-in response (`demoOtpCode`) |
| No-squad test | omar.t@orange.com | Chat/gallery locked |
| Admin | admin@orange.com | admin123 |

Auth verify endpoint: `POST /auth/verify-2fa` (not verify-otp).

---

## 6. Helper scripts

| Script | Purpose |
|--------|---------|
| `deploy-demo-server.sh` | Build + start all backend containers |
| `deploy-mobile-web.sh` | Build Flutter web → gateway `/app/` |
| `verify-mobile-api.sh` | Governance + JWT + Swagger + chat smoke |
| `verify-localhost.sh` | Full local feature verification |
| `verify-backend.sh` | Health checks only |
| `start-demo-tunnel.sh` | Cloudflare public URL |
| `build-local-android.sh` | Demo APK for physical Android devices |

---

## 7. Android demo APK

```bash
cd apps/mobile
./build-local-android.sh
```

Output: `build/android-dist/myboss-demo-<lan-ip>.apk`

Install on phone (same Wi‑Fi as Mac, or use Cloudflare tunnel URL baked into the APK).

---

## 8. Troubleshooting

| Issue | Fix |
|-------|-----|
| Build fails | `docker compose ... build --no-cache` |
| Port in use | `docker compose ... down`; `lsof -i :8090` |
| 401 on squad/chat | Pass `Authorization: Bearer {token}` |
| Mobile web stale | `ALLOW_DEPLOY=1 ./infrastructure/scripts/deploy-mobile-web.sh` |

---

*Orange — my boss app — Docker*
