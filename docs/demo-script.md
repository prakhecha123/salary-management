# Demo Video Script

A ~4-5 minute walkthrough. Record your screen going through these in order;
narrate what you're doing and why as you go, since the assessment says
they'll ask about your reasoning in the follow-up interview anyway — good
practice for saying it out loud once first.

1. **Requirements doc (30s).** Open `requirements.md`. Say what the tool is
   for, name one thing you deliberately left out and why (e.g. no live FX
   conversion) — shows scoping judgment, not just code output.

2. **Employee list (60s).** Open the deployed app. Show the 10,000-row list.
   Search by name. Filter by country + department together. Point out this
   is server-side pagination, not loading 10k rows into the browser.

3. **Employee detail + salary history (60s).** Click into one employee.
   Show the salary history table — more than one row, because salary is
   modeled as history, not a single field. Click "Record Salary Change,"
   add a raise, show it appear at the top of the history and become the new
   current salary.

4. **Add an employee (45s).** Click "Add Employee," fill the form including
   the initial salary, submit. Land on the new employee's detail page. Note
   in passing that the employee + their first salary record are created in
   one transaction — creating an employee never leaves them without a
   salary.

5. **Dashboard (60s).** Open the Dashboard. Point at total payroll cost and
   average salary — these are the "how does the org pay people" questions
   from the brief. Point out the country and department breakdowns are all
   converted to USD from each employee's local currency.

6. **Tests (30s).** Briefly show the test suite running
   (`bundle exec rspec` and `npm test`) and the passing count. Mention one
   specific interesting test — e.g. the one that verifies terminated
   employees are excluded from payroll cost, or that only the _latest_
   salary record counts as "current."

7. **Close (15s).** One sentence on what you'd build next if this weren't
   time-boxed (e.g. bulk CSV import, org chart) and why it wasn't in v1.
