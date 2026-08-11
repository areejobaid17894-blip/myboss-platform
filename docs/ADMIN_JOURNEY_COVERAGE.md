# Admin Journey Coverage — HTML Mockup + Platform PDF vs Admin Portal

Reference designs:

- **Admin HTML mockup:** `the BOSS Admin web page Demo V2 July 2026.html` (11 nav sections, black sidebar)
- **Platform journey PDF:** `v1 Platform employee journey Rev 1.0 July 2026.pptx.pdf` (admin acceptance criteria on screens #14–16)

Admin portal: `myboss-admin/` — **the Boss — Admin Console** at http://127.0.0.1:5173 (Vite dev) or `:8081` (Docker).

## Navigation coverage (HTML V2)

| HTML section | Route | Status | Data source |
|--------------|-------|--------|-------------|
| Overview | `/` | ✅ | squad stats, users, company report |
| Statistics | `/statistics` | ✅ | survey analytics + derived KPIs |
| Squads | `/squads` | ✅ | `GET /squads/admin/all` (members included) |
| Destinations | `/destinations` | ✅ | AI geo + `PUT /squads/:id/destination` |
| Unregistered | `/unregistered` | ✅ | users + `POST /squads/admin/assign` |
| Notifications | `/notifications` | ✅ | `POST /notifications`, `GET /notifications/history` → linked gallery card |
| Data extraction | `/extraction` | ✅ | CSV exports + analytics datasets |
| Surveys | `/surveys` | ✅ | survey-service CRUD |
| Photos | `/photos` | ✅ | `GET /gallery?source=employee` (employee uploads only) |
| Vests | `/vests` | ✅ | user profiles + squad members |
| Audit log | `/audit` | ✅ Demo | localStorage (DB audit = future) |
| Configuration | `/configuration` | ✅ | config-service |

Legacy routes redirect: `/users` → `/unregistered`, `/analytics` → `/statistics`, `/dashboard` → `/`.

## PDF / journey admin requirements

| Requirement (journey doc) | Admin coverage |
|---------------------------|----------------|
| Admin OTP sign-in | ✅ `/login` — `admin-sign-in` + `verify-2fa` |
| Review squad formation progress | ✅ Overview KPIs + Squads table |
| Override AI destination | ✅ Destinations → `PUT /squads/:id/destination` |
| Assign unregistered employees | ✅ Unregistered → `POST /squads/admin/assign` (syncs `user.squad_id`) |
| Push notifications to segments | ✅ Notifications → creates gallery announcement + employee inbox |
| Export data for Power BI | ✅ Extraction + Statistics CSV |
| Gallery extraction by governorate | ✅ Photos (employee uploads) + gallery API |
| Vest procurement views | ✅ Vests page |
| Audit trail of admin actions | ✅ Audit page (browser persistence in demo) |
| Survey schema management | ✅ Surveys page |
| App limits (squad size, targets) | ✅ Configuration page |

## Demo vs production gaps

| Feature | Demo behaviour | Production target |
|---------|----------------|-------------------|
| AI destinations (preview) | Client heuristic before save | Server-side AI service |
| Notifications | Survey-service JSON + API | Notification service + FCM/APNs |
| Audit log | localStorage | Append-only audit table |
| Statistics satisfaction mix | Illustrative when sparse | NLP / classified survey pipeline |
| Photo ZIP extract | CSV manifest | Object storage signed URL bundle |

## URLs & access

| Environment | Admin login | Swagger (Squad) |
|-------------|-------------|-----------------|
| Local gateway | http://127.0.0.1:8090/login | http://127.0.0.1:8090/squad/api/v1/docs |
| Public tunnel | `https://<host>/login` (see `demo-public-url.txt`) | `https://<host>/squad/api/v1/docs` |

Account: `admin@orange.com` / `admin123` + OTP (auto-fill when `DEMO_MODE=true`).

## Related docs

- [EMPLOYEE_JOURNEY_COVERAGE.md](./EMPLOYEE_JOURNEY_COVERAGE.md)
- [GALLERY_NOTIFICATIONS.md](./architecture/GALLERY_NOTIFICATIONS.md)
- [NOTIFICATIONS_PRODUCTION.md](./architecture/NOTIFICATIONS_PRODUCTION.md)
- [DATABASE.md](../database/DATABASE.md)
- [TEAM_REVIEW_GUIDE.md](./TEAM_REVIEW_GUIDE.md)
