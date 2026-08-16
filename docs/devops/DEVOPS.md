# DevOps — how to run and what CI/CD should deploy

**Scope:** two containers only.

| Container | Image source | Port | Role |
|-----------|--------------|------|------|
| `myboss-api` | `myboss-backend/docker/Dockerfile` | **3001** | Employee + admin API |
| `myboss-admin` | `myboss-admin/docker/Dockerfile` | **8081** | Admin web UI |

Mobile (Flutter) is **not** deployed with this stack.  
This repo does **not** ship deploy scripts. **DevOps CI/CD** builds the two images, injects GitLab variables, and starts Compose (or equivalent).

Laptop run: [`INSTALL.md`](../INSTALL.md).  
Stages: [`../deployment/STAGES.md`](../deployment/STAGES.md).  
Variable list: [`../deployment/ENV_AND_GITLAB_VARIABLES.md`](../deployment/ENV_AND_GITLAB_VARIABLES.md).

---

## Repos

| Clone | GitLab |
|-------|--------|
| `myboss-backend` | https://github.com/areejobaid17894-blip/myboss-backend |
| `myboss-admin` | https://github.com/areejobaid17894-blip/myboss-admin |
| `myboss-platform` | https://github.com/areejobaid17894-blip/myboss-platform |

`.env` is **never** in git. Production / preprod / development values come from **GitLab → Settings → CI/CD → Variables**.

---

## What CI/CD should do

1. Checkout the three repos as siblings (same parent folder).
2. Materialize `myboss-platform/.env` from GitLab variables (or a File variable `MYBOSS_RUNTIME_ENV`).
3. From `myboss-platform`:

```bash
docker compose up -d --build
```

4. Health: `GET http://127.0.0.1:3001/api/v1/health` → `"status":"ok"`.
5. Admin: `http://<DEMO_HOST>:8081/login`.

Changing `DEMO_HOST` requires a **rebuild** of `myboss-admin` (Vite bakes the API URL).

Compose file: [`docker-compose.yml`](../../docker-compose.yml) (repo root).

---

## GitLab variable templates

| Stage | Run file | GitLab file |
|-------|----------|-------------|
| Development | [`.env.development.example`](../../.env.development.example) | [`gitlab-development.env.example`](gitlab-development.env.example) |
| Production | [`.env.production.example`](../../.env.production.example) | [`gitlab-production.env.example`](gitlab-production.env.example) |
| Preprod (staging) | [`.env.preprod.example`](../../.env.preprod.example) | [`gitlab-preprod.env.example`](gitlab-preprod.env.example) |

Same **key names** on every stage. Mask secrets. Prefer **group** `myboss` variables for `MYSQL_*`, `JWT_SECRET`, and Orange OTP keys.

---

## Host requirements

| Need | Value |
|------|--------|
| OS | Linux (Ubuntu 22.04+) |
| Docker | 24+ with Compose v2 |
| MySQL (dev + prod) | `10.1.165.105:3308` database `my_boss` |
| MySQL (preprod) | Dedicated DB — fill `MYSQL_*` in `.env.preprod.example` when DBA provides it |
| OTP (dev + prod) | `10.4.3.27:9001` |
| OTP (preprod / staging) | `10.1.112.95:9001` + hosts `10.1.112.95 preprod-notification.xyz.jt.jtgroup` |
| Publish | `3001`, `8081` (or load balancer → these) |
| RAM | 4 GB min · 8 GB recommended |

Do **not** run extra API containers. Do **not** run a local MySQL for the app. Keep `MYSQL_CONNECTION_LIMIT=1` and `DB_SYNCHRONIZE=false`.

---

## Stages (OTP vs DB)

| Stage | `APP_ENV` | MySQL | Orange SSO + Maxit |
|-------|-----------|-------|---------------------|
| Development | `development` | Production DB | Production (`10.4.3.27`) |
| Production | `production` | Same production DB | Same production Maxit (`10.4.3.27`) |
| Preprod (staging) | `preprod` | Dedicated preprod DB (fill later) | Preprod APIs |

Force OTP with `ORANGE_OTP_ENV=production` or `preprod`.

---

## Local / server Compose (no scripts)

```bash
cd /opt/myboss   # or ~/myboss
# siblings: myboss-backend, myboss-admin, myboss-platform

cd myboss-platform
cp .env.example .env   # fill secrets, or write .env from GitLab
docker compose up -d --build
curl http://127.0.0.1:3001/api/v1/health
```

Stop: `docker compose down`.  
Logs: `docker compose logs -f api admin`.

| Check | URL |
|-------|-----|
| API health | `http://127.0.0.1:3001/api/v1/health` |
| Swagger (non-prod) | `http://127.0.0.1:3001/docs` |
| Admin | `http://<DEMO_HOST>:8081/login` |

---

## Admin image build args

| Arg / env | Meaning |
|-----------|---------|
| `DEMO_HOST` | Public hostname or IP baked into the SPA |
| `ADMIN_BUILD_MODE` | `demo` (laptop) or `production` |
| `VITE_APP_ENV` | `development` / `preprod` / `production` |
| `VITE_API_URL` | Optional override of `http://<DEMO_HOST>:3001/api/v1` |

---

*Orange — my boss app*
