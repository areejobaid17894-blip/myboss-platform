# DevOps — Docker images (backend + admin only)

**Do not use `myboss-platform` for deploy.** Clone and build:

| Repo | Dockerfile | Container port |
|------|------------|----------------|
| https://github.com/areejobaid17894-blip/myboss-backend | `Dockerfile` (repo root) | **80** (`APP_PORT`; do not set GitLab `PORT`) |
| https://github.com/areejobaid17894-blip/myboss-admin | `docker/Dockerfile` | **80** (`APP_PORT`; do not set GitLab `PORT`) |

GitLab CI/CD Variables are injected as **container environment at runtime**. Images contain no application secrets and no public URLs.

Canonical templates: [`../../myboss-backend/docs/gitlab/README.md`](https://github.com/areejobaid17894-blip/myboss-backend/-/blob/dev/docs/gitlab/README.md)

Copies in this repo (for reference only):

| Stage | File |
|-------|------|
| Development | [`gitlab-development.env.example`](gitlab-development.env.example) |
| Preprod | [`gitlab-preprod.env.example`](gitlab-preprod.env.example) |
| Production | [`gitlab-production.env.example`](gitlab-production.env.example) |

Spreadsheet: [`GITLAB_VARIABLES.csv`](GITLAB_VARIABLES.csv)

**Connectivity:** [`CONNECTION_MATRIX.md`](CONNECTION_MATRIX.md)

---

## Docker build

```bash
# myboss-backend
docker build -f Dockerfile -t myboss-api .

# myboss-admin
docker build -f docker/Dockerfile -t myboss-admin .
```

`sh: tsc: not found` → builder installs devDependencies (`NODE_ENV=development`, `npm install --include=dev`). Not a `.dockerignore` gap.

---

## Runtime

- API: all `MYSQL_*`, Orange OTP, `CORS_ALLOWED_ORIGINS`, `JWT_*`, etc. from GitLab.
- Admin: `VITE_API_URL`, `VITE_APP_ENV` (served as `/runtime-config.js`). No Docker build args.
- Preprod / production GitLab: **no localhost**. Do not set `PORT` or `API_INTERNAL_URL`. K8s uses `APP_PORT=80`.

Health: API `GET /api/v1/health` · Admin `GET /health`

Preprod hosts: `10.1.112.95 preprod-notification.xyz.jt.jtgroup`

---

*Orange — my boss app*
