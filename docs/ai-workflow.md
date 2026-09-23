# AI Workflow Notes

This project was built collaboratively with Claude (Claude Code), used as a
pair-programmer rather than a code-generation black box. This log captures
what it was asked to do and where its output was directed, changed, or
rejected, so the development process is auditable rather than opaque.

## Working style

- Requirements and scope were defined first (`requirements.md`), before any
  code, and used as the reference point for every later decision.
- Every non-obvious design decision was required to come with a stated
  reason, captured in `trade-offs.md` as it happened, not reconstructed
  after the fact.
- AI-authored code was reviewed and understood line-by-line before being
  committed, not accepted wholesale, because the author needs to be able to
  defend every decision in a follow-up technical discussion.

## Log

1. **Environment setup.** Asked Claude to scaffold a new Rails API + React
   project. It surfaced that the machine's default Ruby (3.0.0) is EOL and
   fails to compile a transitive gem dependency (`io-console`) against
   modern C extension APIs — rather than pinning old gem versions to work
   around it, upgraded to Ruby 3.3.5 via rvm, since shipping a fresh project
   on an end-of-life runtime would itself be a poor decision to defend later.
2. **Requirements doc.** Asked Claude to draft `requirements.md` from the
   raw problem statement, with explicit non-goals and reasoning per the
   assessment's instructions. Reviewed and would edit before submission if
   any scope call didn't reflect actual intent.
3. **Rails app + gem setup.** Scaffolded `rails new backend --api`, added
   rspec-rails/factory_bot/faker for testing, rack-cors for the frontend,
   pg for production — each addition tied to a concrete need already
   identified in the requirements/trade-offs docs, not a default kitchen-sink
   Gemfile.
4. **Models, API, and tests.** Built `Employee`/`SalaryRecord`/`ExchangeRate`
   plus a `PayrollAnalytics` service (SQL window function over salary
   history, joined to exchange rates, aggregated in the database rather than
   in Ruby, so it scales to 10k+ employees). Asked Claude to write RSpec
   coverage alongside each piece rather than after the fact; reviewed each
   spec for whether it actually tested the interesting behavior (e.g. the
   window-function "latest salary per employee" logic, the transactional
   employee+initial-salary create, terminated employees excluded from
   payroll cost) rather than trivial happy paths.
5. **Seed script.** Asked for a 10,000-employee seed generating realistic,
   defensible salary bands (department base pay × seniority level × country
   cost-of-living factor, converted to local currency) rather than uniform
   random numbers, specifically so the analytics views would show a
   plausible distribution instead of noise. Required bulk `insert_all!`
   instead of per-record `.create` for performance — verified by timing it
   (~3 seconds for 10k employees + ~33k salary records) rather than assuming.
6. **Frontend build and real-browser verification.** Built the React app,
   then actually drove it in a headless browser (Playwright) against the
   live dev servers rather than trusting that lint + unit tests passing
   meant the UI worked — this caught two real things unit tests wouldn't:
   an Ant Design console warning from using the static `message` API
   outside its theme context (fixed by wrapping the app in antd's `<App>`
   component), and confirmed the create-employee → record-a-raise flow
   actually persists and re-renders correctly end to end. The verification
   script itself was disposable tooling, not a deliverable, so it and its
   screenshots were removed once it had done its job rather than left in
   the repo.
7. **Dependency security audit.** Ran `bundler-audit` and `npm audit`
   proactively rather than assuming a fresh `rails new`/`npm create vite`
   scaffold was safe by construction. Found and fixed three real, disclosed
   CVEs: `sqlite3` 1.7.3 (two use-after-free advisories, fixed by bumping to
   `~> 2.9`) and Rails 7.1.6's activesupport (an XSS and a DoS advisory,
   fixed by moving to 7.2.3.2) — full RSpec suite re-verified green after
   each bump before moving on.
