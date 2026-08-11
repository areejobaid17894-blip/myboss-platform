# DevOps & Infrastructure Guide

**Audience:** DevOps, SRE, platform engineers  
**Local install first:** [`INSTALL.md`](../INSTALL.md)

---

## 1. Technology stack (pinned versions)

| Component | Version | Where defined |
|-----------|---------|---------------|
| **Node.js** | **20 LTS** (`node:20-alpine`) | Dockerfiles, CI |
| **TypeScript (backend)** | **5.9.3** | `myboss-backend/package-lock.json` |
| **TypeScript (admin)** | **5.7.3** | `myboss-admin/package-lock.json` |
| **NestJS** | **10.4** | `myboss-backend/package-lock.json` |
| **React** | **19** | `myboss-admin/package-lock.json` |
| **Vite** | **6** | `myboss-admin/package-lock.json` |
| **Flutter** | **3.35.7** | `myboss-mobile/.fvmrc`, `pubspec.yaml` |
| **Dart** | **≥3.9.2 <4.0.0** | `myboss-mobile/pubspec.yaml` |
| **Docker** | **24+** Compose v2 | VM requirement |
| **MariaDB** | **11.4** | Optional (`with-mariadb` profile) |

### Microservices (direct ports — no gateway)

| Service | Port | Local base URL |
|---------|------|----------------|
| auth-service | 3001 | http://127.0.0.1:3001/api/v1 |
| user-service | 3002 | http://127.0.0.1:3002/api/v1 |
| config-service | 3003 | http://127.0.0.1:3003/api/v1 |
| squad-service | 3004 | http://127.0.0.1:3004/api/v1 |
| survey-service | 3005 | http://127.0.0.1:3005/api/v1 |
| notification-service | 3006 | http://127.0.0.1:3006/api/v1 |

Admin SPA: **8081** · Employee web (dev): **8092** · Vite admin dev: **5173**

---

## 2. VM requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| OS | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| CPU | 2 vCPU | 4 vCPU |
| RAM | 4 GB | 8 GB |
| Disk | 30 GB SSD | 50 GB SSD |
| Docker | 24+ Compose v2 | Latest stable |

---

## 3. One-time server setup

### Install Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# Log out and back in
docker --version && docker compose version
```

### Clone all four repos

```bash
sudo mkdir -p /opt/myboss && sudo chown $USER:$USER /opt/myboss
cd /opt/myboss

git clone https://github.com/areejobaid17894-blip/myboss-backend.git
git clone https://github.com/areejobaid17894-blip/myboss-admin.git
git clone https://github.com/areejobaid17894-blip/myboss-mobile.git
git clone https://github.com/areejobaid17894-blip/myboss-platform.git

cd myboss-platform
chmod +x scripts/*.sh
./scripts/install-demo-server.sh /opt/myboss
```

### Environment file

```bash
cd /opt/myboss/myboss-platform
cp .env.example .env
nano .env
```

**Required:**

```env
NODE_ENV=demo
APP_ENV=demo
JWT_SECRET=<openssl rand -base64 48>
INTERNAL_SERVICE_TOKEN=<openssl rand -base64 32>
TWO_FA_DEMO_ENABLED=true
CHAT_ENABLED=true
DEMO_ADMIN_PASSWORD=admin123
DEMO_HOST=127.0.0.1
```

Full list: [`.env.example`](../../.env.example) · GitLab: [`ENV_AND_GITLAB_VARIABLES.md`](../deployment/ENV_AND_GITLAB_VARIABLES.md)

---

## 4. Deploy

```bash
cd /opt/myboss/myboss-platform
./scripts/deploy-demo-server.sh 127.0.0.1
```

Manual equivalent:

```bash
docker compose -f docker/docker-compose.demo.yml up -d --build
docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal
```

**After deploy (local on VM):**

| Component | URL |
|-----------|-----|
| Admin | http://127.0.0.1:8081/login |
| Backend health | http://127.0.0.1:3001/api/v1/health … :3006 |
| Auth Swagger | http://127.0.0.1:3001/api/v1/docs |

Reset demo seed: `./scripts/reset-demo-data.sh`

---

## 5. Verify

```bash
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1
./scripts/verify-localhost.sh
docker compose -f docker/docker-compose.demo.yml ps
```

QA checklist: [`deployment/TESTING.md`](../deployment/TESTING.md)

---

## 6. Platform scripts

| Script | Purpose |
|--------|---------|
| `install-demo-server.sh [DIR]` | One-time VM Docker setup |
| `deploy-demo-server.sh [HOST]` | Build & start backend + admin |
| `stop-demo-server.sh` | Stop demo stack |
| `reset-demo-data.sh` | Restore demo seed |
| `verify-backend.sh` | Health :3001–3006 |
| `verify-mobile-api.sh [HOST]` | API smoke test |
| `verify-localhost.sh` | Full feature smoke test |
| `fix-admin-login.sh` | Fix admin password |

---

## 7. Stop / update

```bash
./scripts/stop-demo-server.sh

cd /opt/myboss/myboss-platform && git pull
cd ../myboss-backend && git pull
cd ../myboss-admin && git pull
./scripts/deploy-demo-server.sh 127.0.0.1
```

---

## 8. CI/CD

| Repo | Pipeline |
|------|----------|
| Backend | `myboss-backend/.gitlab-ci.yml` |
| Admin | `myboss-admin/.gitlab-ci.yml` |
| Mobile | `myboss-mobile/.gitlab-ci.yml` |
| Platform | `myboss-platform/.gitlab-ci.yml` |

Details: [`../cicd/CI_CD.md`](../cicd/CI_CD.md)

---

## 9. DevOps checklist

- [ ] Ubuntu 22.04, Docker 24+, Compose v2
- [ ] All four repos under `/opt/myboss`
- [ ] `.env` with strong `JWT_SECRET` and `INTERNAL_SERVICE_TOKEN`
- [ ] `deploy-demo-server.sh 127.0.0.1` succeeds
- [ ] `verify-backend.sh` and `verify-mobile-api.sh 127.0.0.1` pass
- [ ] Secrets not committed to git

---

*Orange — my boss app — DevOps*
