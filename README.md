# myboss-platform

Laptop compose + docs only. **DevOps does not deploy this repo.**

| Repo | Role |
|------|------|
| `myboss-backend` | NestJS API image (`docker/Dockerfile`) — **DevOps** |
| `myboss-admin` | Admin UI image (`docker/Dockerfile`) — **DevOps** |
| `myboss-platform` | Local Docker Compose + documentation |
| `myboss-mobile` | Flutter employee app (not Docker) |

| You are… | Read |
|----------|------|
| DevOps | [`myboss-backend/docs/gitlab/README.md`](https://github.com/areejobaid17894-blip/myboss-backend/-/blob/dev/docs/gitlab/README.md) |
| Laptop | [`docs/INSTALL.md`](docs/INSTALL.md) |
| GitLab variables | [`docs/deployment/ENV_AND_GITLAB_VARIABLES.md`](docs/deployment/ENV_AND_GITLAB_VARIABLES.md) |

```bash
cd myboss-platform
cp .env.example .env
docker compose up -d --build
curl http://127.0.0.1:3001/api/v1/health
```

---

*Orange — my boss app*
