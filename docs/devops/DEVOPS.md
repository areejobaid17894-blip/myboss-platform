# DevOps & Infrastructure Guide

**Audience:** DevOps, SRE, platform engineers  
**Purpose:** Pinned versions, installation, deployment, verification, and Apigee wiring

**Related:** [`deployment/APIGEE_CONNECTION.md`](../deployment/APIGEE_CONNECTION.md) · [`deployment/ENV_AND_GITLAB_VARIABLES.md`](../deployment/ENV_AND_GITLAB_VARIABLES.md) · [`NEW_DEVICE_SETUP.md`](../NEW_DEVICE_SETUP.md)

---

## 1. Technology stack (pinned versions)

### Runtimes & languages

| Component | Version | Where defined |
|-----------|---------|---------------|
| **Node.js** | **20 LTS** (`node:20-alpine`) | Dockerfiles, CI |
| **TypeScript (backend)** | **5.9.3** | `myboss-backend/package-lock.json` |
| **TypeScript (admin)** | **5.7.3** | `myboss-admin/package-lock.json` |
| **Flutter** | **3.35.7** | `myboss-mobile/pubspec.yaml`, `.fvmrc` |
| **Dart** | **≥3.9.2 <4.0.0** | `myboss-mobile/pubspec.yaml` |

### Backend — NestJS 10 microservices

| Service | Port | Apigee prefix | Health |
|---------|------|---------------|--------|
| auth-service | 3001 | `/auth/api/v1` | `/api/v1/health` |
| user-service | 3002 | `/user/api/v1` | `/api/v1/health` |
| config-service | 3003 | `/config/api/v1` | `/api/v1/health` |
| squad-service | 3004 | `/squad/api/v1` | `/api/v1/health` |
| survey-service | 3005 | `/survey/api/v1` | `/api/v1/health` |
| notification-service | 3006 | `/notification/api/v1` | `/api/v1/health` |

Shared library: `myboss-backend/libs/common`

### Admin portal

React 19 · Vite 6 · axios — builds with `npm run build:apigee` for demo/production.

### Mobile

Flutter 3.35.7 · BLoC · app version **1.0.0+1**

### Docker images

| Image | Tag | Usage |
|-------|-----|--------|
| node | 20-alpine | Backend service builds |
| nginx | alpine | Admin SPA static files only (port **8081**) |
| mariadb | 11.4 | Optional shared DB (`with-mariadb` profile) |
| redis | 7-alpine | Optional local cache |

**There is no nginx API gateway.** Clients call **Orange Apigee**; Apigee routes to VM ports 3001–3006.

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
| **3001–3006** | Microservices | Apigee / internal only |
| **8081** | Admin SPA (static) | Optional direct access |
| **3306** | MariaDB | Internal (`DB_ENABLED=true`) |
| **5173** | Vite dev | Local development only |

Apigee terminates TLS publicly at `https://api-demo.orange.com`.

---

## 3. Architecture (deploy view)

```
Mobile app / Admin SPA
        │
        ▼
Orange Apigee  (https://api-demo.orange.com)
        │
        ▼
Demo VM — Docker (ports 3001–3006)
        │
        ├── auth-service      :3001
        ├── user-service      :3002
        ├── config-service    :3003  (+ chat)
        ├── squad-service     :3004
        ├── survey-service    :3005
        └── notification-service :3006
```

Admin Docker container (8081) serves static files only — the SPA calls Apigee for APIs.

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

**Required for demo:**

```env
NODE_ENV=demo
APP_ENV=demo
JWT_SECRET=<openssl rand -base64 48>
INTERNAL_SERVICE_TOKEN=<openssl rand -base64 32>
TWO_FA_DEMO_ENABLED=true
CHAT_ENABLED=true
DEMO_ADMIN_PASSWORD=admin123
DEMO_HOST=<server-public-ip>
```

Full variable list: [`.env.example`](../../.env.example) · GitLab mapping: [`ENV_AND_GITLAB_VARIABLES.md`](../deployment/ENV_AND_GITLAB_VARIABLES.md)

---

## 5. Build & deploy (Docker Compose)

### Deploy backend + admin

```bash
cd /opt/myboss/myboss-platform
./scripts/deploy-demo-server.sh <SERVER_PUBLIC_IP>
```

Equivalent manual compose:

```bash
docker compose -f docker/docker-compose.demo.yml up -d --build
docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal
```

**After deploy:**

| Component | URL |
|-----------|-----|
| Backend health | `http://<VM>:3001/api/v1/health` … `:3006` |
| Admin (Docker) | `http://<VM>:8081` |
| Apigee (clients) | `https://api-demo.orange.com` |

Wire Apigee proxies to `<VM_IP>:3001–3006` — see [`APIGEE_CONNECTION.md`](../deployment/APIGEE_CONNECTION.md).

### Reset demo data (before QA)

```bash
./scripts/reset-demo-data.sh
```

---

## 6. Verify deployment

```bash
./scripts/verify-backend.sh
./scripts/verify-mobile-api.sh 127.0.0.1
./scripts/verify-mobile-api.sh --apigee    # after Apigee is wired
./scripts/verify-localhost.sh

docker compose -f docker/docker-compose.demo.yml ps
```

### Swagger (direct ports on VM)

| Service | URL |
|---------|-----|
| Auth | http://127.0.0.1:3001/api/v1/docs |
| User | http://127.0.0.1:3002/api/v1/docs |
| Config | http://127.0.0.1:3003/api/v1/docs |
| Squad | http://127.0.0.1:3004/api/v1/docs |
| Survey | http://127.0.0.1:3005/api/v1/docs |
| Notification | http://127.0.0.1:3006/api/v1/docs |

QA guide: [`deployment/TESTING.md`](../deployment/TESTING.md)

---

## 7. Firewall

```bash
sudo ufw allow OpenSSH
sudo ufw allow from <APIGEE_IP_RANGE> to any port 3001:3006 proto tcp
sudo ufw allow 8081/tcp   # optional — admin SPA direct access
sudo ufw enable
```

Do **not** expose 3001–3006 to the public internet — only Apigee should reach them.

---

## 8. Stop / update / rollback

```bash
# Stop
./scripts/stop-demo-server.sh

# Update after git pull
cd /opt/myboss/myboss-platform && git pull
cd ../myboss-backend && git pull
cd ../myboss-admin && git pull
./scripts/deploy-demo-server.sh <SERVER_IP>
```

---

## 9. Platform scripts

| Script | Purpose |
|--------|---------|
| `install-demo-server.sh [DIR]` | One-time VM Docker setup |
| `deploy-demo-server.sh [HOST]` | Build & start backend + admin Docker |
| `start-demo-server.sh` | Compose up only (no verify output) |
| `stop-demo-server.sh` | Stop demo stack |
| `reset-demo-data.sh` | Restore in-memory demo seed |
| `verify-backend.sh` | Health checks :3001–3006 + push status |
| `verify-mobile-api.sh [HOST]` | Mobile API governance (direct ports) |
| `verify-mobile-api.sh --apigee` | Same checks through Apigee |
| `verify-localhost.sh` | Full feature smoke test |
| `fix-admin-login.sh` | Recreate auth if admin password fails |

---

## 10. Docker file locations

```
docker/
├── Dockerfile.auth
├── Dockerfile.user
├── Dockerfile.config
├── Dockerfile.squad
├── Dockerfile.survey
├── Dockerfile.notification
├── Dockerfile.admin-portal
├── docker-compose.demo.yml
├── docker-compose.yml
└── mariadb/init/
```

---

## 11. CI/CD

| Repo | Pipeline file |
|------|---------------|
| Backend | `myboss-backend/.gitlab-ci.yml` |
| Admin | `myboss-admin/.gitlab-ci.yml` |
| Mobile | `myboss-mobile/.gitlab-ci.yml` |
| Platform | `myboss-platform/.gitlab-ci.yml` |

Details: [`../cicd/CI_CD.md`](../cicd/CI_CD.md) · Secrets: [`ENV_AND_GITLAB_VARIABLES.md`](../deployment/ENV_AND_GITLAB_VARIABLES.md)

---

## 12. DevOps checklist

- [ ] VM meets CPU/RAM/disk specs (Ubuntu 22.04)
- [ ] Docker 24+ and Compose v2 installed
- [ ] All four repos cloned under `/opt/myboss`
- [ ] `.env` with strong `JWT_SECRET` and `INTERNAL_SERVICE_TOKEN`
- [ ] `deploy-demo-server.sh` succeeds; `verify-backend.sh` passes
- [ ] Apigee proxies route to VM `:3001–3006`
- [ ] `verify-mobile-api.sh --apigee` passes
- [ ] Firewall: 3001–3006 restricted to Apigee; not public
- [ ] Admin built with Apigee URLs (`build:apigee` / Docker default)
- [ ] Secrets not committed to git

---

*Orange — my boss app — DevOps*
