# Architecture

## System overview

```mermaid
flowchart LR
    HR["HR Manager\n(browser)"] --> FE["React SPA\n(Vite + Ant Design)"]
    FE -- "JSON over HTTPS" --> API["Rails API\n(ActionController::API)"]
    API --> DB[("SQLite (dev/test)\nPostgreSQL (production)")]

    subgraph Rails API
        EC[EmployeesController]
        SC[SalaryRecordsController]
        AC[AnalyticsController]
        RC[ReferenceDataController]
        PA[PayrollAnalytics service]
        EC --> DB
        SC --> DB
        AC --> PA --> DB
        RC -.-> Const["OrganizationReferenceData\n(in-code constants)"]
    end
```

The frontend never talks to the database directly — every read and write
goes through the Rails API as plain JSON. `PayrollAnalytics` is a separate
service object rather than logic inlined in `AnalyticsController` because
the aggregation query (see below) is the one piece of business logic
substantial enough to want its own unit tests independent of the HTTP layer.

## Data model

```mermaid
erDiagram
    EMPLOYEE ||--o{ SALARY_RECORD : "has history of"
    SALARY_RECORD }o--|| EXCHANGE_RATE : "converted via (currency match)"

    EMPLOYEE {
        string employee_number UK
        string first_name
        string last_name
        string email UK
        string country
        string department
        string job_title
        string status
        date hire_date
    }
    SALARY_RECORD {
        int employee_id FK
        decimal amount
        string currency
        date effective_date
        string reason
    }
    EXCHANGE_RATE {
        string currency UK
        decimal rate_to_usd
    }
```

The deliberate choice here — covered in more depth in `trade-offs.md` — is
that `SALARY_RECORD` is a history, not a column on `EMPLOYEE`. An employee's
"current salary" is a derived read (latest `effective_date`, tie-broken by
`id`), not a stored fact, so a raise or correction is always an _addition_
to the record, never an overwrite. `EXCHANGE_RATE` isn't a foreign key
relationship in the schema (there's no `exchange_rate_id` column) — it's
joined at query time by matching `currency`, so adding a new supported
currency never requires backfilling existing salary records.

## Request flow: recording a raise

```mermaid
sequenceDiagram
    participant U as HR Manager
    participant FE as React SPA
    participant API as Rails API
    participant DB as Database

    U->>FE: Fill "Record Salary Change" form, Save
    FE->>API: POST /employees/:id/salary_records
    API->>DB: INSERT salary_records (validated)
    DB-->>API: OK
    API->>DB: Reload employee + salary_records
    API-->>FE: Full employee JSON (new current salary + history)
    FE-->>U: Table re-renders with the new row on top
```

No employee attributes change when a raise is recorded — only a new
`SalaryRecord` row is inserted. This is the same "history over mutation"
principle applied at the request level.
