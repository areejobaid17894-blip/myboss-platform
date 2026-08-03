# my boss app — Testing Guide

**Audience:** QA, developers, DevOps  
**Covers:** Backend smoke tests, Swagger, auth, chat, mobile checklist

---

## 1. Automated verification (recommended)

```bash
# Reset demo data before a test cycle (squads, terms, seed users)
./infrastructure/scripts/reset-demo-data.sh

# Gateway + JWT + Swagger + chat
./infrastructure/scripts/verify-mobile-api.sh 127.0.0.1 --gateway

# Full localhost (squad, chat send/reply, surveys)
./infrastructure/scripts/verify-localhost.sh

# Backend health only
./infrastructure/scripts/verify-backend.sh
```

---

## 2. Swagger UI (interactive API docs)

| Service | Local gateway | Direct port |
|---------|---------------|-------------|
| Auth | http://127.0.0.1:8090/auth/api/v1/docs | :3001 |
| User | http://127.0.0.1:8090/user/api/v1/docs | :3002 |
| Config (+ **Chat**) | http://127.0.0.1:8090/config/api/v1/docs | :3003 |
| Squad | http://127.0.0.1:8090/squad/api/v1/docs | :3004 |
| Survey | http://127.0.0.1:8090/survey/api/v1/docs | :3005 |

**Public tunnel:** append `/auth/api/v1/docs` etc. to your Cloudflare base URL.

To test JWT endpoints in Swagger: Authorize → `Bearer {accessToken}`.

---

## 3. Backend health

```bash
curl http://127.0.0.1:8090/health
curl http://127.0.0.1:8090/auth/api/v1/health
```

---

## 4. Auth flow (employee)

```bash
# Step 1 — Sign in
curl -X POST http://127.0.0.1:8090/auth/api/v1/auth/sign-in \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@orange.com"}'

# Response includes sessionId and demoOtpCode (demo mode)

# Step 2 — Verify OTP (endpoint is verify-2fa)
curl -X POST http://127.0.0.1:8090/auth/api/v1/auth/verify-2fa \
  -H "Content-Type: application/json" \
  -d '{"sessionId":"<SESSION_ID>","code":"<OTP>"}'
```

Expected: `accessToken`, `refreshToken`, `user`.

**Orange error format** on failure:

```json
{ "code": 41, "reason": "Invalid credentials", "message": "..." }
```

---

## 5. Chat API test (native squad messaging)

Full reference: [`docs/api/CHAT_API.md`](../../api/CHAT_API.md)

```bash
# Public
curl http://127.0.0.1:8090/config/api/v1/chat/config
curl http://127.0.0.1:8090/config/api/v1/chat/health

# JWT required
curl http://127.0.0.1:8090/config/api/v1/chat/visitor \
  -H "Authorization: Bearer <ACCESS_TOKEN>"

# Send message
curl -X POST http://127.0.0.1:8090/config/api/v1/chat/messages \
  -H "Authorization: Bearer <ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"recipientId":"1","text":"QA test message"}'

# Poll messages
curl "http://127.0.0.1:8090/config/api/v1/chat/messages?peerId=1" \
  -H "Authorization: Bearer <ACCESS_TOKEN>"
```

**Mobile chat rules:**
- User must be in a **squad** (`demo@orange.com` ✓, `omar.t@orange.com` ✗)
- Contacts = squad members only

---

## 6. Admin flow

1. Open: **http://127.0.0.1:8090/login** (gateway — preferred) or public tunnel `/login`
2. Login: `admin@orange.com` / `admin123` → OTP
3. Verify V2 console: black sidebar, **Overview** landing page
4. Test: Squads table loads, assign on Unregistered, save on Destinations

Swagger: http://127.0.0.1:8090/squad/api/v1/docs

---

## 7. Through Apigee (after connection)

Replace base with `https://api-demo.orange.com`:

```bash
curl https://api-demo.orange.com/auth/api/v1/health
curl https://api-demo.orange.com/config/api/v1/chat/config
```

See [`03_APIGEE_CONNECTION.md`](03_APIGEE_CONNECTION.md).

---

## 8. Mobile app manual test

| Step | Action | Expected |
|------|--------|----------|
| 0 | Run `reset-demo-data.sh` | Fresh squads; all users must accept T&C |
| 1 | Open `/app/`, sign in `demo@orange.com` | OTP → **terms popup** → home |
| 2 | Toggle EN / AR | Labels change |
| 3 | Tap **Live Chat** FAB (any tab) | Squad contact picker |
| 4 | Select squad member, send message | Message appears; peer can reply |
| 5 | Sign in `omar.t@orange.com` | Terms → squad hub; no-squad gating |
| 6 | Sign in `nisreen.a@orange.com` | Leader view; remove member (if added) |
| 7 | Join squad → browse list | All squads; filter by governorate |
| 8 | Reports tab (omar) | Locked panel — no charts |
| 9 | Gallery tab | Upload locked without squad |
| 10 | Profile → Log out | Returns to sign-in |
| 11 | Session wait / invalid token | Redirect to sign-in |

### Squad browse API (JWT required)

```bash
curl -s http://127.0.0.1:8090/squad/api/v1/squads \
  -H "Authorization: Bearer <ACCESS_TOKEN>" | jq .
```

Expected: JSON array with `Orange Amman Squad` and other demo squads.

---

## 9. Backend unit tests

```bash
cd apps/backend
npm run test:auth
npm run test:user
npm run test:config
npm run test:squad
npm run test:survey
```

---

## 10. Test checklist

- [ ] All 5 health endpoints OK
- [ ] All 5 Swagger UIs load
- [ ] Employee sign-in + verify-2fa works
- [ ] JWT required on squad/user/chat (401 without token)
- [ ] Orange error envelope on 401
- [ ] Squad create/join works
- [ ] Chat send + poll between squad members
- [ ] Squad browse lists all squads (`GET /squads`)
- [ ] Join squad governorate filter + search (mobile)
- [ ] Reports locked for no-squad user (`omar.t@orange.com`)
- [ ] Chat locked for no-squad user (FAB opens locked panel)
- [ ] Survey submit + catalog works
- [ ] Gallery upload (in-squad user)
- [ ] Mobile EN/AR + logout + session redirect
- [ ] Apigee paths (post-integration)

---

*Orange — my boss app — QA*
