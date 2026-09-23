# Salary Management Software — Requirements

## Goal

Give ACME's HR team a web application to manage salary data for ~10,000 employees
across multiple countries, replacing spreadsheets, and to let an HR Manager answer
questions about how the organization pays people (by country, department, role,
and over time) without manual spreadsheet work.

## Primary user

HR Manager. Not payroll/finance (no tax, statutory deduction, or payslip
generation), and not the employee self-service view (employees don't log in).

## In scope

- **Employee records**: name, employee ID, email, country, department, job
  title, employment status (active/terminated), hire date.
- **Salary as a history, not a single field.** Every salary change (initial
  offer, raise, adjustment) is a dated record with an amount, currency, and
  optional reason. This is the central modeling decision: an HR Manager's real
  question is rarely "what does X earn today" alone — it's "how has this
  changed" and "how do we compare across the org." A single mutable
  `salary` column on `Employee` cannot answer either.
- **Browse & search**: paginated, filterable (country, department, status),
  searchable (name/employee ID) list of employees — must stay usable at
  10,000 rows.
- **Employee detail view**: profile + full salary history timeline.
- **Record a salary change**: add a new salary record with effective date,
  amount, currency, reason.
- **Org-level analytics** ("how do we pay people"): headcount and average/
  median salary by country and by department, total payroll cost, and
  distribution (e.g. min/max/median) per department. These are the concrete
  "questions" the problem statement says the HR Manager needs answered.
- **Seed data**: a script generating 10,000 employees with realistic,
  country-appropriate salary bands and at least one salary history entry
  each, so analytics and pagination are exercised meaningfully.

## Explicitly out of scope (and why)

- **Authentication / authorization / multi-tenant orgs.** The brief describes
  a single HR Manager persona and a single org (ACME). Adding real auth would
  spend the assessment's time budget on plumbing instead of the salary domain
  it's meant to probe. A single implicit "logged in as HR Manager" context is
  assumed.
- **Payroll processing (tax withholding, statutory deductions, payslips,
  actual bank disbursement).** This is a _salary management_ tool, not a
  payroll run engine — those are different, much larger systems in practice,
  and the brief's questions ("how do we pay people") are about visibility,
  not execution.
- **Live currency conversion via an FX API.** Aggregating payroll cost across
  countries needs a common currency, but calling a live FX API adds an
  external dependency, network flakiness, and API-key management for a
  take-home. Instead, a small static exchange-rate table (seeded, editable)
  converts to USD for aggregate views only; each employee's own currency is
  always shown as the source of truth on their record. This is called out
  because it is a real simplification with a real consequence: cross-country
  totals are only as current as the static table.
- **Employee self-service.** Employees do not log in to view their own
  salary; that's a different product with different auth/privacy needs.
- **Org chart / manager hierarchy, bonus/equity tracking.** Real HR systems
  track these, but they're additive features orthogonal to the core "manage
  and query salary" problem — left out to keep the core model sharp rather
  than broad.
- **Bulk import/export (CSV upload) of employee data.** Likely the first
  feature a real HR team would ask for next, but it's additive on top of the
  core CRUD + history model, not required to demonstrate the core engineering
  decisions.

## Architecture (summary — see `docs/` for detail)

- **Backend**: Ruby on Rails (API-only), SQLite in development/test,
  PostgreSQL in production (see `docs/trade-offs.md` for why these differ).
- **Frontend**: React (Vite) + Ant Design, chosen for its strength in
  data-table-heavy admin UIs (server-side pagination/sorting/filtering out of
  the box), talking to the Rails API over JSON.
- **Tests**: RSpec (model validations, request specs for the API), a small
  set of frontend tests for core display/formatting logic.
