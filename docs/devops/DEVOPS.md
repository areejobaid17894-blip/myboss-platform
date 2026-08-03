# DevOps & Infrastructure Guide

**Audience:** DevOps, SRE, platform engineers  
**Purpose:** Full technology stack, pinned versions, installation, deployment, and verification

---

## 1. Technology stack (pinned versions)

### Runtimes & languages

| Component | Version | Where defined |
|-----------|---------|---------------|
| **Node.js** | **20 LTS** (`node:20-alpine`) | Dockerfiles, GitHub Actions |
| **TypeScript (backend)** | **5.9.3** (lock) | `myboss-backend/package-lock.json` |
| **TypeScript (admin)** | **5.7.3** (lock) | `myboss-admin/package-lock.json` |
| **Flutter** | **3.35.7** | `myboss-mobile/pubspec.yaml`, `myboss-mobile/.fvmrc` |
| **Dart** | **≥3.9.2 <4.0.0** | `myboss-mobile/pubspec.yaml` |

### Backend — NestJS 10 microservices

| Package | Locked version |
|---------|----------------|
| @nestjs/common, @nestjs/core | 10.4.22 |
| @nestjs/swagger | 7.4.2 |
| @nestjs/jwt | 10.2.0 |
| express | 4.22.1 |
| jsonwebtoken | 9.0.2 |
| class-validator | 0.14.4 |
| swagger-ui-dist | 5.17.14 |
| jest | 29.7.0 |

| Service | Port | Apigee prefix | Health |
|---------|------|---------------|--------|
| auth-service | 3001 | `/auth/api/v1` | `/api/v1/health` |
| user-service | 3002 | `/user/api/v1` | `/api/v1/health` |
| config-service | 3003 | `/config/api/v1` | `/api/v1/health` |
| squad-service | 3004 | `/squad/api/v1` | `/api/v1/health` |
| survey-service | 3005 | `/survey/api/v1` | `/api/v1/health` |

Shared library: `myboss-backend/libs/common` (Orange errors, JWT, Swagger, security headers).

### Admin portal

| Package | Locked version |
|---------|----------------|
| React / react-dom | 19.2.8 |
| Vite | 6.4.3 |
| react-router-dom | 7.18.1 |
| axios | 1.18.1 |
| vitest | 3.2.7 |

### Mobile (Flutter)

| Package | Locked version |
|---------|----------------|
| flutter_bloc | 9.1.1 |
| dio | 5.10.0 |
| go_router | 15.1.3 |
| flutter_secure_storage | 9.2.4 |

App version: **1.0.0+1**

### Docker images

| Image | Tag | Usage |
|-------|-----|--------|
| node | 20-alpine | Backend service builds |
| nginx | 1.27-alpine | API gateway (port **8090**) |
| nginx | alpine | Admin portal container |
| postgres | 16-alpine | Optional local DB (`docker-compose.yml`) |
| redis | 7-alpine | Optional local cache |

### External tools (demo)

| Tool | Notes |
|------|-------|
| Docker Compose | v2+ required |
| cloudflared | Optional public tunnel (`start-demo-tunnel.sh`) |
| FVM | Flutter version manager — `myboss-mobile/.fvmrc` |

---

## 2. Server specifications

### Demo event profile

| Item | Value |
|------|-------|
| Duration | ~1 week event |
| Load | ~1,500 users/day |
| Environment | Demo (pre-production) |

### VM requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| OS | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| CPU | 2 vCPU | 4 vCPU |
| RAM | 4 GB | 8 GB |
| Disk | 30 GB SSD | 50 GB SSD |
| Docker | 24+ Compose v2 | Latest stable |

### Network ports

| Port | Service | Exposure |
|------|---------|----------|
| **8090** | API gateway — mobile `/app/`, admin `/login`, all API proxies | Public (Apigee / Cloudflare) |
| 3001–3005 | Microservices | Apigee / internal only |
| 8081 | Admin portal direct (optional) | Internal; prefer **8090/login** |
| 5432 | PostgreSQL | Internal (future) |
| 6379 | Redis | Internal (future) |
| 5173 | Vite dev server | Local development only |

---

## 3. Architecture (deploy view)

```
Mobile / Admin  →  nginx gateway :8090  →  Docker containers (3001–3005)
                         │
                         ├── /auth/   → auth-service
                         ├── /user/   → user-service
                         ├── /config/ → config-service (+ chat)
                         ├── /squad/  → squad-service
                         └── /survey/ → survey-service
```

Production target: same path structure behind **Orange Apigee** — see [`../deployment/pdf/03_APIGEE_CONNECTION.md`](../deployment/pdf/03_APIGEE_CONNECTION.md).

---

## 4. One-time server setup

### Install Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# Log out and back in
docker --version
docker compose version
```

Or use the repo script:

```bash
git clone https://github.com/areejobaid17894-blip/myboss-backend.git /opt/myboss/myboss-backend
git clone https://github.com/areejobaid17894-blip/myboss-admin.git /opt/myboss/myboss-admin
git clone https://github.com/areejobaid17894-blip/myboss-mobile.git /opt/myboss/myboss-mobile
git clone https://github.com/areejobaid17894-blip/myboss-platform.git /opt/myboss/myboss-platform
cd /opt/myboss/myboss-platform
chmod +x scripts/*.sh
./scripts/install-demo-server.sh /opt/myboss
```

### Environment file

```bash
cd /opt/myboss/myboss-platform
cp .env.example .env
nano .env
```

**Required for demo:**

```env
NODE_ENV=demo
APP_ENV=demo
JWT_SECRET=<openssl rand -base64 48>
INTERNAL_SERVICE_TOKEN=<openssl rand -base64 32>
TWO_FA_DEMO_ENABLED=true
CHAT_ENABLED=true
DEMO_HOST=<server-ip>
```

Never commit `.env`. Full variable list: [`.env.example`](../../.env.example).

---

## 5. Build & deploy (Docker Compose)

### Start backend services

```bash
cd /opt/myboss/myboss-platform
./scripts/start-demo-server.sh
```

Equivalent:

```bash
docker compose -f docker/docker-compose.demo.yml up -d --build
docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal
```

**With admin portal container:**

```bash
docker compose -f docker/docker-compose.demo.yml \
  --profile with-admin up -d --build admin-portal
```

### Deploy gateway + mobile web

```bash
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
```

This serves:
- Mobile web: `http://<host>:8090/app/`
- Admin: `http://<host>:8090/login`
- API proxies: `http://<host>:8090/{auth|user|config|squad|survey}/api/v1/...`

### Optional public URL (Cloudflare tunnel)

```bash
./scripts/start-demo-tunnel.sh
# URL written to demo-public-url.txt in myboss-platform
```

### Reset demo data (before team testing)

In-memory stores mutate during QA. Restore seed squads, users, and terms state:

```bash
./scripts/reset-demo-data.sh
```

Rebuilds **user-service** and **survey-service**, restarts **auth** and **squad**. See [`../database/DATABASE.md` § Demo data reset](../database/DATABASE.md#demo-data-reset).

---

## 6. Verify deployment

```bash
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1 --gateway
./scripts/verify-localhost.sh

docker compose -f docker/docker-compose.demo.yml ps
curl -s http://127.0.0.1:8090/health
```

### Swagger (via gateway)

| Service | URL |
|---------|-----|
| Auth | http://127.0.0.1:8090/auth/api/v1/docs |
| User | http://127.0.0.1:8090/user/api/v1/docs |
| Config | http://127.0.0.1:8090/config/api/v1/docs |
| Squad | http://127.0.0.1:8090/squad/api/v1/docs |
| Survey | http://127.0.0.1:8090/survey/api/v1/docs |

---

## 7. Firewall

```bash
sudo ufw allow OpenSSH
sudo ufw allow 8090/tcp                    # gateway (or restrict to Apigee/CDN IPs)
sudo ufw allow from <APIGEE_IP_RANGE> to any port 3001:3005 proto tcp
sudo ufw enable
```

---

## 8. Stop / update / rollback

```bash
# Stop
./scripts/stop-demo-server.sh

# Update after git pull
git pull
./scripts/start-demo-server.sh
ALLOW_DEPLOY=1 ./scripts/deploy-mobile-web.sh
```

---

## 9. Docker file locations

```
docker/
├── Dockerfile.auth
├── Dockerfile.user
├── Dockerfile.config
├── Dockerfile.squad
├── Dockerfile.survey
├── Dockerfile.admin-portal
├── docker-compose.demo.yml    ← demo backend (primary)
├── docker-compose.yml         ← postgres + redis only
├── nginx-api-gateway.conf
├── nginx-admin.conf
└── README.md
```

---

## 10. CI/CD (GitHub Actions)

| Workflow | Path | Trigger |
|----------|------|---------|
| Backend CI | `myboss-backend/.gitlab-ci.yml` | Backend repo |
| Admin CI | `myboss-admin/.gitlab-ci.yml` | Admin repo |
| Mobile CI | `myboss-mobile/.gitlab-ci.yml` | Mobile repo |
| Platform | `myboss-platform/.gitlab-ci.yml` | Docs / deploy scripts |

Deploy jobs are placeholders until wired to your registry/K8s. Details: [`../cicd/CI_CD.md`](../cicd/CI_CD.md).

---

## 11. DevOps checklist

- [ ] VM meets CPU/RAM/disk specs (Ubuntu 22.04)
- [ ] Docker 24+ and Compose v2 installed
- [ ] `.env` created with strong `JWT_SECRET` and `INTERNAL_SERVICE_TOKEN`
- [ ] `docker compose ... up -d --build` succeeds
- [ ] Gateway **8090** serves `/app/`, `/login`, API proxies
- [ ] `verify-backend.sh` and `verify-mobile-api.sh --gateway` pass
- [ ] Firewall: 8090 public (or via CDN); 3001–3005 restricted
- [ ] Apigee can reach backend (see Apigee guide)
- [ ] Secrets not committed to git

---

## Related documentation

| Document | Purpose |
|----------|---------|
| [`../security/SECURITY.md`](../security/SECURITY.md) | Security controls & hardening |
| [`../database/DATABASE.md`](../database/DATABASE.md) | Database schema |
| [`../deployment/DEPLOYMENT.md`](../deployment/DEPLOYMENT.md) | Environment matrix |
| [`../deployment/pdf/03_APIGEE_CONNECTION.md`](../deployment/pdf/03_APIGEE_CONNECTION.md) | Apigee proxy setup |
| [`../deployment/pdf/04_TESTING_GUIDE.md`](../deployment/pdf/04_TESTING_GUIDE.md) | QA verification |

---

*Orange — my boss app — DevOps*
