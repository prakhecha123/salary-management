# Trade-offs & Design Notes

Running log of non-obvious decisions and why they were made, kept separate
from `requirements.md` (which is the user-facing scope doc) so this can stay
a working log without cluttering that document.

## Salary as a history table, not a column

`Employee` does not have a `salary` column. Instead there is a
`SalaryRecord` model: `employee_id`, `amount`, `currency`, `effective_date`,
`reason`. An employee's "current salary" is derived (the record with the
latest `effective_date`), not stored redundantly.

Why: the problem statement's core question is "how does the org pay people,"
which is inherently about change over time (raises, adjustments, offer vs.
current) — not just a snapshot. Modeling salary as an immutable append-only
history means:

- Nothing is ever overwritten, so there's an audit trail for free.
- "What was this person's salary in March" and "how many raises has this
  department given this year" are simple queries, not reconstructions from
  a changelog no one built.
- The trade-off: slightly more query complexity to get "current salary"
  (need latest-per-employee), which is a legitimate cost, mitigated with a
  DB index on `(employee_id, effective_date)`.

## SQLite in dev/test, Postgres in production

Rails' own convention is same-adapter everywhere to avoid adapter-specific
SQL differences. Here they deliberately differ:

- The assessment explicitly suggests SQLite ("Relational database of your
  choice, like SQLite") for simplicity — no local Postgres install needed to
  run this.
- But the deliverable requires a fully working _deployed_ app, and Render's
  free web service tier has an ephemeral filesystem — a SQLite file would be
  wiped on every deploy or restart, silently losing all seeded/entered data.
- Postgres in production avoids that; the app only uses standard ActiveRecord
  (no adapter-specific SQL), so the risk of dev/prod behavior divergence is
  low and acceptable for this scope.

## No live FX conversion

Cross-country aggregates (e.g. total payroll cost) need one currency. A
static, seeded exchange-rate table converts to USD for aggregation only;
per-employee records always show their real local-currency amount. A live
FX API was deliberately rejected for a take-home: it adds a runtime external
dependency and a key-management concern for no benefit the assessment
actually needs. Documented here so it doesn't read as an oversight — it's a
scoped trade-off with a known cost (rates go stale until manually updated).

## Unoptimized frontend bundle

The production build is a single ~1.2MB (385KB gzipped) JS bundle — Vite
warns about this. Ant Design accounts for most of it. Code-splitting (route-
based lazy loading, `manualChunks`) would fix this properly, but for an
internal HR tool used by a handful of people on a fast connection, load time
isn't the constraint worth spending assessment time on; noted here so it
reads as a known, deliberately deferred optimization rather than an
oversight.

## Frontend dev-tooling on Node 16, not 20

This machine's available Node is 16.15.1; installing Node 20 via Homebrew
repeatedly failed on this network (a dependency patch fetch from
`ftp.gnu.org` timed out both times, ~15+ minutes each attempt). Given that,
Vite is pinned to v4 and Vitest to v0.34 — the last major lines that support
Node 16 — rather than the project silently breaking on `npm install` for
anyone else on an older Node.

Running `npm audit` on this pin set surfaces two dev-tooling advisories that
were deliberately left unpatched, since fixing them requires Vite 6+/Vitest
3+, which need Node 18+:

- **esbuild ≤0.24.2 (moderate, GHSA-67mh-4wv8-2f99):** a malicious website
  can query Vite's local dev server. This only matters if the dev server is
  reachable from an untrusted network while running, which it never is here
  (local dev only; the deployed build is static files served by Render, not
  this dev server).
- **Vitest <3.2.6 (critical, GHSA-5xrq-8626-4rwp):** arbitrary file read via
  the Vitest UI server. This project never runs `vitest --ui`, so the
  vulnerable code path is never invoked. `npm test` runs `vitest run`, which
  doesn't start that server.

A third advisory — a real one, `react-router` 6.0.0–7.17.0's open-redirect/
deserialization CVEs — **was** fixed, by bumping to `react-router-dom@7.18.4`
directly (it still declares `node >=14.0.0`, so it didn't require the Node
20 upgrade the other two would have). Likewise, two backend advisories found
via `bundler-audit` (`sqlite3` 1.7.3's use-after-free CVEs, and
`activesupport` 7.1.6's XSS/DoS CVEs) were fixed outright by bumping to
`sqlite3 ~> 2.9` and Rails 7.2.3.2 — see the git history for both.

The distinction driving what got fixed vs. deferred: exploitability given
how this app actually runs, not just advisory severity labels taken at face
value.

## Component library: Ant Design over Material UI / Chakra

This is fundamentally an internal admin/data tool: a 10,000-row searchable,
filterable, sortable table is the single most-used piece of UI. Ant Design's
`Table` component supports server-side pagination/sorting/filtering
natively, which is exactly the shape of the core interaction — using it
avoids hand-rolling pagination logic in components MUI/Chakra would otherwise
require building.
