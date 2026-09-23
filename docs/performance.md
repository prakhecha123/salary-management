# Performance Considerations

Concrete decisions made because of the 10,000-employee scale requirement,
each verified rather than assumed.

## Seeding 10,000 employees: bulk insert, not 10,000 `.create` calls

`db/seeds.rb` builds plain Ruby hashes and writes them with
`Employee.insert_all!` / `SalaryRecord.insert_all!` in batches of 1,000,
instead of calling `.create` per record. `.create` would run every
validation and callback (including the `employee_number` auto-assignment
query) 10,000 times, each a separate `INSERT`. Bulk insert bypasses that —
correctly, since the seed script itself is responsible for satisfying the
constraints instead (see the comment at the top of `seeds.rb`).

Verified, not assumed: timed with `time bundle exec rails db:seed` —
10,000 employees + ~33,000 salary records in ~3 seconds.

## Payroll analytics: aggregation in SQL, not Ruby

`PayrollAnalytics` (see `docs/architecture.md` for the query) uses a SQL
window function (`ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY
effective_date DESC, id DESC)`) to find each employee's current salary,
joined to `exchange_rates` for USD conversion, aggregated with
`SUM`/`AVG`/`MIN`/`MAX` in one query per breakdown, plus a second query for
the median (a `ROW_NUMBER`/`COUNT` "middle row" pattern — see the comment in
`payroll_analytics.rb`) merged into the same result in Ruby. Two queries
instead of one because a database-portable median can't be expressed as a
plain aggregate function the way `AVG`/`MIN`/`MAX` can — it still runs
entirely in SQL, just as two statements rather than one.

The alternative — loading every `SalaryRecord` into Ruby and reducing over
them — would pull tens of thousands of rows into the app process on every
dashboard load, for a computation the database is already built to do.
Aggregating in SQL means the dashboard's cost is roughly constant relative
to app-server memory, regardless of headcount.

## Employee list: server-side pagination, not client-side

`GET /employees` accepts `page`/`per_page` (capped at 100) and does the
`LIMIT`/`OFFSET` in the database, returning only that page plus a `meta`
block with `total_count`. The React table's pagination is wired to that
`meta`, not to an array already sitting in the browser. Rendering a
10,000-row Ant Design table client-side, or shipping 10,000 rows over the
wire on first paint, would make the single most-used screen the slowest one
— pagination keeps every list request's payload roughly the same size
regardless of total headcount.

## Indexes chosen to match actual query patterns

- `employees(country)`, `employees(department)`, `employees(status)` —
  each is an independent filter on the list endpoint (see `Employee`'s
  `in_country`/`in_department`/`with_status` scopes).
- `employees(employee_number)` and `employees(email)` — both unique and
  looked up directly (the former by URL/search, the latter by validation).
- `salary_records(employee_id, effective_date)` — matches the "latest
  record per employee" access pattern used everywhere: the `current_salary_record`
  association order, and the window function's `PARTITION BY … ORDER BY`.

The employee **search** (`LOWER(first_name) LIKE '%term%'` etc.) is
deliberately _not_ index-backed — a leading wildcard `LIKE` can't use a
standard B-tree index regardless, so no index was added to pretend
otherwise. At 10,000 rows a full scan for search is fast enough in practice;
if search became a bottleneck at a materially larger scale, the real fix
would be a dedicated search index (e.g. Postgres full-text search or an
external search service), not a database index that wouldn't help this
query shape anyway.

## Exchange rate lookups aren't cached, and don't need to be

`SalaryRecord#amount_in_usd` calls `ExchangeRate.find_by(currency:)` per
record. On the employee list page this runs once per row on the page (≤100
per request). Rails' per-request `ActiveRecord::QueryCache` deduplicates
identical repeated queries within one request — verified in the development
log: a page of 20 employees all from the same country (so all sharing one
currency) produced 1 real `ExchangeRate Load` and 19 `CACHE ExchangeRate
Load` hits, for 19 of 23 total queries served from cache. A page with mixed
currencies doesn't get this benefit (each distinct currency is still a real
query), but with only 7 currencies total the worst case is 7 real queries
per request regardless of how many of the 100 rows on the page there are.
Adding an application-level cache on top would be solving a cost that
doesn't exist yet.

## A real N+1 found and fixed on the employee detail endpoint

`GET /employees/:id` used to run two separate `SalaryRecord` queries for one
employee: `current_salary_record` (`salary_records.first`) and the full
history list (`salary_records.map`) each issued their own `SELECT`, because
calling `.first` on a not-yet-loaded `has_many` executes a targeted query
without marking the association loaded — so the following `.map` triggers a
second one. Fixed by eager-loading in the controller
(`Employee.includes(:salary_records).find(...)`), the same pattern already
used on the list endpoint, so both accessors share one preloaded array.
Verified by clearing the development log, hitting the endpoint, and counting
query lines before (2 `SalaryRecord Load`) and after (1) the fix — the kind
of thing that's easy to introduce silently and easy to miss without actually
reading the SQL log rather than assuming `.includes` elsewhere covers it.

## What's deliberately not optimized

The unoptimized ~1.2MB frontend bundle (see `trade-offs.md`) is the one
known-but-accepted performance gap — code-splitting would fix it, but for
an internal tool used by a handful of HR staff, load time isn't the
constraint worth spending the assessment's time budget on.
