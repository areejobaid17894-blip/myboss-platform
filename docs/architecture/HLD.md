# my boss app — High-Level Design (HLD)

Simple overall view of the system.

---

## 1. What is it?

**my boss app** is an Orange employee initiative platform. Employees form **squads**, run field activities, collect **surveys**, and upload photos. **Admins** manage users, settings, surveys, and export reports to **Power BI**.

---

## 2. Big picture

```mermaid
flowchart TB
    subgraph Clients
        MA[Employee Mobile App<br/>Flutter / Android]
        AP[Admin Portal<br/>React Web]
    end

    subgraph Backend["Backend — NestJS Microservices"]
        AUTH[Auth Service]
        USER[User Service]
        CONFIG[Config Service]
        SQUAD[Squad Service]
        SURVEY[Survey Service]
    end

    subgraph Data
        DB[(MariaDB — myboss)]
    end

    subgraph External
        PBI[Power BI]
    end

    MA --> AUTH
    MA --> USER
    MA --> CONFIG
    MA --> SQUAD
    MA --> SURVEY

    AP --> AUTH
    AP --> USER
    AP --> CONFIG
    AP --> SURVEY

    AUTH --> DB
    USER --> DB
    CONFIG --> DB
    SQUAD --> DB
    SURVEY --> DB

    PBI -->|CSV / JSON export| SURVEY
```

---

## 3. Main parts

| Layer | Technology | Who uses it |
|-------|------------|-------------|
| **Mobile app** | Flutter (Android) | Employees |
| **Admin portal** | React + Vite | Admins |
| **Backend** | NestJS (5 microservices) | Both apps |
| **Database** | MariaDB 11 — single shared `myboss` database | All backend services |
| **Analytics** | CSV/JSON export APIs | Power BI / Admin |

---

## 4. Backend services

| Service | Main job |
|---------|----------|
| **Auth** | Login, 2FA OTP, JWT tokens |
| **User** | Employee profiles and accounts |
| **Config** | Squad limits, buildings, app settings, **live chat config (Apigee)** |
| **Squad** | Create/join squads, members, leaders |
| **Survey** | Surveys, responses, gallery, notifications, reports, Power BI export |

---

## 5. MariaDB — what is stored

All microservices connect to **one database** (`MARIADB_DATABASE=myboss`). No duplicate user or squad snapshot columns — see [`../database/DATABASE.md`](../database/DATABASE.md).

| Domain | Examples |
|--------|----------|
| **Auth & users** | Single `users` table (eligibility + profile), OTP sessions |
| **Config** | Buildings, app settings, squad limits |
| **Squads** | Squads, members, join requests |
| **Surveys** | Survey schemas, responses, gallery, notifications, analytics |

> **Note:** Demo defaults to in-memory data (`DB_ENABLED=false`). Enable MariaDB with `DB_ENABLED=true` for persistent, report-ready data.

---

## 6. Employee flow (Mobile)

```mermaid
flowchart LR
    A[Sign in<br/>@orange.com] --> B[2FA OTP]
    B --> C[Onboarding]
    C --> D[Create / Join Squad]
    D --> E[Run Surveys]
    E --> F[Gallery & Reports]
```

**Main screens:** Sign in → OTP → Home → My Squad → Surveys → Gallery → Profile

---

## 7. Admin flow (Web — V2 Console)

```mermaid
flowchart LR
    A[Admin login<br/>email + password] --> B[2FA OTP]
    B --> C[Overview KPIs]
    C --> D[Squads / Destinations / Unregistered]
    D --> E[Statistics & Extraction]
    E --> F[Export to Power BI]
```

**Main sections (V2):** Overview · Statistics · Squads · Destinations · Unregistered · Notifications · Extraction · Surveys · Photos · Vests · Audit

**Entry URL:** `http://<gateway>:8090/login` or public tunnel `/login`

---

## 8. Survey data flow

```mermaid
sequenceDiagram
    participant E as Employee App
    participant S as Survey Service
    participant D as MariaDB (myboss)
    participant A as Admin Portal
    participant P as Power BI

    E->>S: Submit survey answers
    S->>D: Save response
    A->>S: GET reports / analytics
    S->>D: Read aggregated data
    A->>S: Download CSV
    P->>S: Import CSV
```

---

## 9. Security (high level)

| Role | Authentication |
|------|----------------|
| **Employee** | `@orange.com` email + OTP |
| **Admin** | Email + password + OTP |
| **API** | JWT bearer token on requests |

---

## 10. Deployment view (development)

```mermaid
flowchart LR
    DEV[Developer Machine]
    DEV --> BE[Backend Services]
    DEV --> EMU[Android Emulator]
    DEV --> WEB[Admin Portal Browser]
    BE --> DB[(MariaDB myboss)]

    EMU --> BE
    WEB --> BE
```

---

## 11. One-line summary

> **Flutter mobile app for employees + React admin portal + NestJS microservices + MariaDB (`myboss`)**, centered on **squads, dynamic surveys, and Power BI-ready analytics**.

---

## Related docs

- [ARCHITECTURE.md](./ARCHITECTURE.md) — detailed architecture
- [../deployment/](../deployment/) — deployment guides
