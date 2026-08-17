# Environment variables & GitLab CI/CD

DevOps deploys **myboss-backend** and **myboss-admin** only (not this platform repo).  
Same **key names** on development, preprod, and production. Inject as **container env at runtime** — not Docker build args.

| Stage | GitLab template (backend) |
|-------|---------------------------|
| Preprod | [`../devops/gitlab-preprod.env.example`](../devops/gitlab-preprod.env.example) |
| Production | [`../devops/gitlab-production.env.example`](../devops/gitlab-production.env.example) |
| Development | [`../devops/gitlab-development.env.example`](../devops/gitlab-development.env.example) |

Canonical copies: `myboss-backend/docs/gitlab/`. CSV: [`../devops/GITLAB_VARIABLES.csv`](../devops/GITLAB_VARIABLES.csv).

---

## Stages

| | Development | Production | Preprod (staging) |
|--|-------------|------------|-------------------|
| `APP_ENV` | `development` | `production` | `preprod` |
| MySQL | `10.1.165.105:3308` / `my_boss` | **same as development** | `10.1.169.88:3308` / `my_boss_pre` / user `my_boss_app_pre` |
| `ORANGE_OTP_ENV` | `production` | `production` | `preprod` |
| SSO | `http://10.4.3.27:9001/...` | **same** | `http://10.1.112.95:9001/...` |
| Email | `http://10.4.3.27:9001/.../email/send` | **same** | `http://preprod-notification.xyz.jt.jtgroup/email/send` |
| OTP recipient | Login email | Login email | Login email |
| `VITE_API_URL` (admin **runtime**) | `http://127.0.0.1:3001/api/v1` | `TODO_DEPLOY_API_PUBLIC_URL/api/v1` | `TODO_PREPROD_API_PUBLIC_URL/api/v1` |
| `CORS_ALLOWED_ORIGINS` | `http://127.0.0.1:8081,...` | `TODO_DEPLOY_ADMIN_PUBLIC_URL` | `TODO_PREPROD_ADMIN_PUBLIC_URL` |
| `VITE_APP_ENV` | `development` | `production` | `preprod` |
| `SWAGGER_ENABLED` | default on (non-prod) | `false` | `false` |
| `MYSQL_CONNECTION_LIMIT` | `1` | `1` | `1` |
| `DB_SYNCHRONIZE` | `false` | `false` | `false` |

**Production / preprod GitLab:** no `localhost` / `127.0.0.1` in any variable. Do not set `PORT` or `API_INTERNAL_URL`. Cluster listen port is K8s `APP_PORT=80`. `VITE_API_URL` and `CORS_ALLOWED_ORIGINS` are public ingress URLs only.

---

## Mask in GitLab

`MYSQL_PASSWORD`, `JWT_SECRET`, `INTERNAL_SERVICE_TOKEN`, `ORANGE_SSO_CLIENT_SECRET`, `ORANGE_SSO_API_KEY`, `ORANGE_EMAIL_API_KEY`, `DEMO_ADMIN_PASSWORD`.

---

## Admin

`VITE_API_URL` is read at **container runtime** (`/runtime-config.js`). Changing the API URL does **not** require rebuilding the admin image.

Local Vite: `myboss-admin/.env.development`.

---

## Removed / unused

- `REDIS_*`
- `OTP_TEST_REDIRECT_EMAIL`
- `ADMIN_BUILD_MODE`, `DEMO_HOST` (replaced by runtime `VITE_API_URL`)
