# myboss-platform

Docker Compose, deploy scripts, and documentation for **my boss app**.

---

## Install & run (start here)

**[docs/INSTALL.md](docs/INSTALL.md)** — clone, configure, deploy, open all apps locally.

**DevOps / VM:** [docs/devops/DEVOPS.md](docs/devops/DEVOPS.md)

---

## Quick start

```bash
cp .env.example .env && chmod +x scripts/*.sh
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh
```

| App | Local URL |
|-----|-----------|
| Admin | http://127.0.0.1:8081/login |
| Employee web | http://127.0.0.1:8092 |
| APIs | http://127.0.0.1:3001/api/v1 … :3006 |

**Login:** Admin `admin@orange.com` / `admin123` · Employee `demo@orange.com`

---

## Repos (clone as siblings)

| Repo | Purpose |
|------|---------|
| [myboss-backend](https://github.com/areejobaid17894-blip/myboss-backend) | NestJS microservices |
| [myboss-admin](https://github.com/areejobaid17894-blip/myboss-admin) | React admin portal |
| [myboss-mobile](https://github.com/areejobaid17894-blip/myboss-mobile) | Flutter employee app |
| **myboss-platform** | Docker + scripts + docs |

---

## Versions

Node **20 LTS** · NestJS **10.4** · React **19** · Vite **6** · Flutter **3.35.7**

---

*Orange — my boss app*
