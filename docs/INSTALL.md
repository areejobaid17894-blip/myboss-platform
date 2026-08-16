# Install & run (laptop)

Two processes: **API :3001** and **admin :8081**. Server / CI/CD: [`devops/DEVOPS.md`](devops/DEVOPS.md).

---

## Rules

1. Development and production share corporate MySQL — `MYSQL_HOST=10.1.165.105` · `MYSQL_PORT=3308` · `MYSQL_DATABASE=my_boss`. Preprod uses a dedicated DB when DBA provides it.  
2. `MYSQL_CONNECTION_LIMIT=1` · `DB_SYNCHRONIZE=false`.  
3. OTP is Orange (`OTP_PROVIDER=orange`, `TWO_FA_DEMO_ENABLED=false`). Development and production use production Maxit; preprod (staging) uses preprod APIs. [`deployment/STAGES.md`](deployment/STAGES.md).  
4. Never commit `.env` or filled `.env.development` / `.env.production` / `.env.preprod`.

---

## Tools

Docker Desktop **24+** (Compose v2). Optional: Node **20** (admin Vite), Flutter **3.35.7** (employee app).

---

## Clone

```bash
mkdir -p ~/myboss && cd ~/myboss
git clone https://github.com/areejobaid17894-blip/myboss-backend.git
git clone https://github.com/areejobaid17894-blip/myboss-admin.git
git clone https://github.com/areejobaid17894-blip/myboss-platform.git
git clone https://github.com/areejobaid17894-blip/myboss-mobile.git   # optional on API host
```

---

## Environment

```bash
cd myboss-platform
cp .env.development.example .env   # or .env.production.example / .env.preprod.example
# Fill MYSQL_PASSWORD, JWT_SECRET, INTERNAL_SERVICE_TOKEN, ORANGE_*
```

| Area | Local values |
|------|----------------|
| Stage | `APP_ENV=development` · `DEMO_HOST=127.0.0.1` |
| MySQL | `DB_ENABLED=true` · `10.1.165.105:3308` · `my_boss` (same as production) |
| OTP | `ORANGE_OTP_ENV=production` and production Maxit URLs (same as production) |

Quote passwords that contain `$`: `MYSQL_PASSWORD='p@$$word'`.

Keys: [`deployment/ENV_AND_GITLAB_VARIABLES.md`](deployment/ENV_AND_GITLAB_VARIABLES.md).

---

## Run (Docker)

```bash
cd myboss-platform
docker compose up -d --build
curl http://127.0.0.1:3001/api/v1/health
```

| App | URL |
|-----|-----|
| Admin | http://127.0.0.1:8081/login |
| Admin (Vite) | http://127.0.0.1:5173 — `cd ../myboss-admin && npm i && npm run dev` |
| API | http://127.0.0.1:3001/api/v1 · [Swagger](http://127.0.0.1:3001/docs) |

Stop: `docker compose down`.

Admin login: `admin@orange.com` / `admin123` → OTP emailed.  
Employee app: see `myboss-mobile/README.md` (not in Docker). Offline surveys: [`mobile/OFFLINE_SURVEYS.md`](mobile/OFFLINE_SURVEYS.md).

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Docker on Windows | Enable WSL integration for Ubuntu |
| Hub timeout | `docker pull node:20-alpine` |
| Admin cannot call API | Rebuild with `DEMO_HOST=127.0.0.1` |
| `$` in MySQL password | Quote it in `.env` |
| OTP fails | Host must reach `10.4.3.27:9001` (or preprod URLs when `ORANGE_OTP_ENV=preprod`) |

---

*Orange — my boss app*
