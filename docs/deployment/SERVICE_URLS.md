# Local service URLs

Clients call **microservices directly**. No Apigee. No nginx API gateway.

All URLs below use **`127.0.0.1`** (same machine as Docker).

---

## Apps

| App | URL |
|-----|-----|
| Admin (Docker) | http://127.0.0.1:8081/login |
| Admin (Vite dev) | http://127.0.0.1:5173 |
| Employee web | http://127.0.0.1:8092 |

---

## Microservices

| Service | Port | Base URL | Swagger |
|---------|------|----------|---------|
| auth-service | 3001 | http://127.0.0.1:3001/api/v1 | http://127.0.0.1:3001/api/v1/docs |
| user-service | 3002 | http://127.0.0.1:3002/api/v1 | http://127.0.0.1:3002/api/v1/docs |
| config-service | 3003 | http://127.0.0.1:3003/api/v1 | http://127.0.0.1:3003/api/v1/docs |
| squad-service | 3004 | http://127.0.0.1:3004/api/v1 | http://127.0.0.1:3004/api/v1/docs |
| survey-service | 3005 | http://127.0.0.1:3005/api/v1 | http://127.0.0.1:3005/api/v1/docs |
| notification-service | 3006 | http://127.0.0.1:3006/api/v1 | http://127.0.0.1:3006/api/v1/docs |

---

## Deploy command

```bash
cd myboss-platform
./scripts/deploy-demo-server.sh 127.0.0.1
```

Admin Docker is built with `DEMO_HOST=127.0.0.1` so the browser reaches APIs on the same machine.

---

*Orange — my boss app*
