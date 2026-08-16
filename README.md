# myboss-platform

Compose, env templates, and install/deploy docs for **my boss app**.

**Runtime:** two containers — `myboss-api` (:3001) and `myboss-admin` (:8081).  
**Deploy:** DevOps CI/CD (this repo has no deploy scripts).

| Repo | Role |
|------|------|
| `myboss-backend` | NestJS API |
| `myboss-admin` | Admin UI |
| `myboss-platform` | Compose + `.env` + docs |
| `myboss-mobile` | Flutter employee app (not Docker) |

| You are… | Read |
|----------|------|
| Laptop | [`docs/INSTALL.md`](docs/INSTALL.md) |
| DevOps / CI/CD | [`docs/devops/DEVOPS.md`](docs/devops/DEVOPS.md) |
| GitLab variables | [`docs/deployment/ENV_AND_GITLAB_VARIABLES.md`](docs/deployment/ENV_AND_GITLAB_VARIABLES.md) |
| Stages | [`docs/deployment/STAGES.md`](docs/deployment/STAGES.md) |

```bash
cd myboss-platform
cp .env.example .env
docker compose up -d --build
curl http://127.0.0.1:3001/api/v1/health
```

---

*Orange — my boss app*
