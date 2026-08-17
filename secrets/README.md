# Runtime secrets (not in git)

Real credentials live here on each machine or in GitLab CI/CD / Kubernetes secrets. **Never commit** filled JSON keys or service account files.

## Firebase Cloud Messaging (push)

| File | Tracked? | Purpose |
|------|----------|---------|
| `fcm-service-account.json.example` | Yes (template) | Shows expected shape — copy and fill locally |
| `fcm-service-account.json` | **No** (gitignored) | Firebase Admin SDK JSON for project `my-customer-my-boss` |

Setup:

1. Firebase Console → Project settings → Service accounts → **Generate new private key**
2. Save as `fcm-service-account.json` in this folder (same directory as this README)
3. Set `FCM_ENABLED=true` in `myboss-platform/.env` (gitignored)
4. Redeploy: `docker compose up -d --build`

Full guide: [`docs/PUSH_FIREBASE_SETUP.md`](../docs/PUSH_FIREBASE_SETUP.md)

Docker Compose mounts `./secrets/fcm-service-account.json` read-only into the API container at `/run/secrets/fcm-service-account.json`.
