# my boss app — Open Questions

> **Status:** Demo phase complete for core employee + admin journeys. Items below are **production** or **product** decisions still pending formal sign-off.

Implemented in demo (no longer open): employee OTP auth, squad formation, dynamic surveys, admin V2 console, terms acceptance, vest edit window, native squad chat, gallery/notifications.

---

## Business Requirements

- [x] Core employee roles (`employee`, `admin`, `super_admin`) — demo RBAC in place
- [ ] Complete permissions matrix for production (fine-grained admin actions)
- [x] Sign-in with work email + OTP — demo flow shipped
- [ ] Self-registration vs admin-invite policy for production launch
- [ ] Password policy (admin portal uses demo password + OTP today)
- [ ] Account lockout rules beyond OTP attempt limit
- [ ] Session idle timeout and concurrent session policy

## Authentication & 2FA

- [x] Demo 2FA (in-memory OTP, optional `demoOtpCode` in response)
- [ ] Production 2FA provider (email/SMS gateway)
- [ ] OAuth2 / SSO for admin (Azure AD, Okta, etc.)
- [x] Token refresh endpoint — demo JWT refresh (15m access / 7d refresh)

## UI/UX Design

- [x] Admin Portal V2 layout — see [`ADMIN_JOURNEY_COVERAGE.md`](ADMIN_JOURNEY_COVERAGE.md)
- [ ] Final brand assets and typography sign-off
- [ ] Remaining mobile screens vs HTML mockup gaps — see [`EMPLOYEE_JOURNEY_COVERAGE.md`](EMPLOYEE_JOURNEY_COVERAGE.md)

## Admin Portal — Configuration

- [x] Squad limits, profile edit cap, vest edit date window — configurable in admin
- [ ] Configuration change audit trail (production)
- [ ] Bulk user operations scope

## Backend & Data

- [x] Target schema documented — [`database/DATABASE.md`](database/DATABASE.md)
- [ ] PostgreSQL migration plan and per-service ownership confirmation
- [ ] Inter-service async pattern (events vs synchronous HTTP)
- [ ] Data retention / GDPR requirements
- [ ] Multi-tenancy (if required)

## Reporting & Analytics

- [x] Demo analytics seed + admin Statistics page
- [ ] Power BI integration method (direct DB vs API export)
- [ ] Scheduled report delivery

## Infrastructure & Deployment

- [ ] Target cloud provider confirmation (GCP / Apigee assumed)
- [ ] Production Kubernetes / VM sizing
- [ ] Apigee org and environment details
- [ ] Production monitoring stack

## Localization

- [x] English + Arabic in mobile and admin
- [ ] Phrase workflow and additional languages

## Mobile

- [ ] Minimum supported Android/iOS versions (formal)
- [ ] Offline capability requirements
- [ ] Production OS push (FCM/APNs) — demo uses in-app notifications only  
  See [`architecture/NOTIFICATIONS_PRODUCTION.md`](architecture/NOTIFICATIONS_PRODUCTION.md)
- [ ] App store / MDM distribution strategy

## Security & Compliance

- [ ] Compliance frameworks (SOC 2, ISO 27001, local regulations)
- [ ] Penetration testing before go-live
- [ ] Encryption at rest requirements
- [ ] API rate limiting per environment

---

*Orange — my boss app — update when product signs off remaining items.*
