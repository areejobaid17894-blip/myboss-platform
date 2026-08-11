# myboss-platform

Docker Compose, deploy scripts, and documentation for **my boss app**.

Clients call **microservices directly** on ports **3001–3006**. No Apigee.

**URLs:** [`docs/deployment/SERVICE_URLS.md`](docs/deployment/SERVICE_URLS.md) · **Setup:** [`docs/NEW_DEVICE_SETUP.md`](docs/NEW_DEVICE_SETUP.md)

---

## Deploy locally

```bash
cp .env.example .env && chmod +x scripts/*.sh
./scripts/deploy-demo-server.sh 127.0.0.1
./scripts/verify-backend.sh
```

| App | URL |
|-----|-----|
| Admin | http://127.0.0.1:8081 |
| APIs | http://127.0.0.1:3001/api/v1 … :3006 |

---

## Deploy on a VM (public / LAN IP)

```bash
./scripts/install-demo-server.sh /opt/myboss
cd /opt/myboss/myboss-platform
cp .env.example .env
./scripts/deploy-demo-server.sh <SERVER_IP>

# Admin must be built with the same IP clients use in the browser:
DEMO_HOST=<SERVER_IP> docker compose -f docker/docker-compose.demo.yml --profile with-admin up -d --build admin-portal
```

Example deployed URLs if `SERVER_IP=213.139.63.204`:

- Admin: `http://213.139.63.204:8081`
- Auth: `http://213.139.63.204:3001/api/v1`

Open firewall ports **8081** and **3001–3006**.

---

## Scripts

`deploy-demo-server.sh` · `verify-backend.sh` · `verify-mobile-api.sh` · `verify-orange-otp.sh` · `reset-demo-data.sh` · `stop-demo-server.sh`

---

*Orange — my boss app*
