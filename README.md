# ACME Salary Management

A web application for an HR Manager to manage salary data for ACME's ~10,000
employees across multiple countries, and answer questions about how the
organization pays people. Built for the Incubyte take-home assessment.

**Live**: [frontend](https://salary-management-frontend-nfec.onrender.com) ·
[API](https://salary-management-api-k4bb.onrender.com) — hosted on Render's
free tier, so the first request after ~15 minutes of inactivity takes
30–60s to wake up.

See [`requirements.md`](requirements.md) for scope and explicit non-goals.
Design/engineering reasoning is split across a few docs rather than one long
file:

- [`docs/architecture.md`](docs/architecture.md) — system, data model, and
  request-flow diagrams
- [`docs/trade-offs.md`](docs/trade-offs.md) — non-obvious decisions and why
- [`docs/performance.md`](docs/performance.md) — concrete, verified
  performance decisions at the 10k-employee scale
- [`docs/ai-workflow.md`](docs/ai-workflow.md) — how AI tools were used
  while building this
- [`docs/demo-script.md`](docs/demo-script.md) — the walkthrough for the
  demo video

## Stack

- **Backend**: Ruby on Rails 7 (API-only), SQLite in dev/test, PostgreSQL in
  production
- **Frontend**: React (Vite) + Ant Design
- **Tests**: RSpec (backend), Vitest + React Testing Library (frontend)

## Running locally

### Backend

```bash
cd backend
bundle install
bin/rails db:prepare      # creates and migrates dev + test databases
bin/rails db:seed         # generates 10,000 employees with salary history
bin/rails server -p 3001
```

Requires Ruby 3.3.5 (see `backend/.ruby-version`).

### Frontend

```bash
cd frontend
npm install
npm run dev               # http://localhost:5173
```

Requires Node 16+ (Vite is deliberately pinned to v4 / Vitest to v0.34 for
Node 16 compatibility — see `docs/trade-offs.md`).

By default the frontend talks to `http://localhost:3001`. Override with a
`.env.local` file setting `VITE_API_URL` if the API runs elsewhere.

### Tests

```bash
cd backend && bundle exec rspec
cd frontend && npm test
```

## API

| Method | Path                            | Purpose                                                |
| ------ | ------------------------------- | ------------------------------------------------------ |
| GET    | `/employees`                    | Paginated, filterable, searchable employee list        |
| GET    | `/employees/:id`                | Employee detail + full salary history                  |
| POST   | `/employees`                    | Create an employee and their initial salary record     |
| PATCH  | `/employees/:id`                | Update employee attributes                             |
| POST   | `/employees/:id/salary_records` | Record a raise/adjustment                              |
| GET    | `/analytics/overview`           | Headcount and payroll cost by country/department       |
| GET    | `/reference_data`               | Supported countries, departments, currencies, statuses |
