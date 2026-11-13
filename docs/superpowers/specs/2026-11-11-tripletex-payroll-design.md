# Tripletex payroll: design

Date: 2026-11-11
Starting point: branch `feature/tripletex-integration` (three commits on top of `main` at `3887a63`).

Items marked **(call)** were decided by the author of this document, not by Kasper. Everything else is as Kasper described it.

## Why

Some companies track hours in Tripletex's built-in timesheet because Tripletex then uses those hours for payroll. We want them to be able to track hours in Stemplin and still run payroll in Tripletex without retyping anything.

The existing branch built a different integration (sending report hours to Tripletex as orders for invoicing). That is the wrong one for now. Its connection setup and API client are the right foundation.

## What we are building

1. **Month locking.** An employee locks their hours for a finished month. Locked hours cannot be changed.
2. **Employee linking.** An admin links each Stemplin team member to their Tripletex employee.
3. **Payroll page.** An admin sees every team member's hours and payout amount for a month, and sends each person's pay to Tripletex with one button.

## Goals

- An admin can get one hourly-paid employee's month from Stemplin into a Tripletex payslip with one click.
- The hourly wage is never stored or edited in Stemplin as a setting. It is read from the employee's employment in Tripletex.
- Hours that have been sent for payroll cannot change afterwards.
- Adding fixed-salary employees later means adding one pay rule, not reworking the page.

## Non-goals (for now)

- Fixed monthly salaries, overtime, supplements, piecework, commission.
- Corrections after a month has been sent. Those go in a later month or are fixed by hand in Tripletex.
- A "pay everyone" button.
- Invoicing through Tripletex. The order, PDF and customer-link parts of the branch are removed.
- Moving money. Stemplin creates the payslip. The accountant reviews and pays it out in Tripletex.

## Anti-goals

- An employee paid twice for the same month.
- Hours changing after they were paid.
- A payout sent with a wage that differs from what the admin saw on the page.

## Part 1: Month locking

### For the employee

- The start screen (`time_regs#index`) shows a button "Lock in hours for October" / "Lås timer for oktober".
- The button is shown only when all of these are true:
  - the organization is connected to Tripletex **(call)**,
  - the month has ended **(call)**,
  - the user has hours in that month in this organization that are not locked,
  - the month is not earlier than the month before the Tripletex connection was made **(call)**. This stops the button from offering years of old history.
- If several months qualify, the button offers the oldest one first **(call)**.
- Spectators never see it.
- Clicking opens a confirmation that states the month, the total hours being locked, and that only an admin can undo it.
- Locking is refused while the user has a running timer on an entry in that month **(call)**.
- A lock covers one user, one organization, one calendar month **(call)**. A user in two organizations locks each separately.

### Locking on someone's behalf

- An organization admin can lock a month for any member, from that member's row on the Payroll page. This covers people who have left (archived members cannot log in), are on leave, or do not respond.
- The same conditions apply as for the employee's own button, except the Tripletex-connection cutoff: the month has ended, and no timer is running in it.
- The confirmation names the employee, the month and the total hours.
- The lock records who locked it, so the Payroll page can show "locked by <admin>" when it was not the employee.

### What a lock does

No time entry of that user, in that organization, with a date in the locked month, can be created, edited, deleted, copied into, imported into, or have its timer toggled. That includes:

- moving an entry's date into or out of the locked month,
- admins editing that user's entries. An admin must unlock first **(call)**,
- the JSON API (`api/v1/time_regs`, `api/v1/timers`), which returns a validation error.

The rule must live on the `TimeReg` model so every path is covered, not in individual controllers. The web UI additionally hides the add, edit, delete and timer controls for days in a locked month and shows a "Locked" marker.

### Unlocking

- Only organization admins can unlock, for themselves and for others. They do it from the Payroll page.
- Unlocking is refused once the month has been sent to Tripletex for that user.
- Who locked, who unlocked, and when should be traceable **(call)**. PaperTrail on the lock record is enough.

## Part 2: Linking team members to Tripletex employees

- In the team member edit dialog (`workspace/team_members`), when the organization is connected, an admin sees a dropdown "Tripletex employee" listing the employees from Tripletex. Same pattern as the customer dropdown on the client form in the branch, including the short cache and the inline error when Tripletex is unreachable.
- The link is stored on `AccessInfo` (the user's membership in the organization), as `tripletex_employee_id` **(call)**.
- One Tripletex employee can be linked to at most one member per organization **(call)**.
- When a member has no link and a Tripletex employee has the same email, that employee is preselected in the dropdown **(call)**. Nothing is saved until the admin saves the dialog.
- Unlinked members are also reachable from the Payroll page: the row's action opens this same dialog.

## Part 3: The Payroll page

### Access and placement

- Sidebar item "Payroll" / "Lønn" in the workspace navigation.
- Visible and reachable for organization admins only, and only when the organization is connected to Tripletex.
- A month picker. Defaults to the previous month.

### Rows

One row per team member who is either an active non-spectator member, or has hours in the selected month **(call)**. Archived members with hours in the month are included so their last month can be paid.

Columns: name, hours, hourly wage, amount, status, action.

| Status | When | Hours | Amount | Action |
|---|---|---|---|---|
| Not linked | no Tripletex employee linked | shown | none | Link |
| Not locked | linked, month not locked | shown as preliminary | preliminary | Lock for employee. Shows "waiting for employee to lock" |
| Not handled yet | linked and locked, but not paid by the hour in Tripletex | shown | none | Unlock |
| Ready | linked, locked, paid by the hour | shown | hours × wage | Payout in Tripletex, Unlock |
| Sent | payout sent | as sent | as sent | none. Shows the sent date |
| No hours | no hours in the month | 0 | none | none |

If Tripletex is unreachable, the page still lists members and hours, shows the error once at the top, and offers no payout buttons.

### The amount

- Hours = the sum of the user's minutes in the organization for the month, all projects, billable or not **(call)**. Sent to Tripletex as hours with two decimals.
- Hours on projects or clients that were deleted later still count **(call)**. Projects and clients are soft-deleted and the usual scopes hide their hours, so payroll and the lock total need a query that includes them. Deleted time entries do not count.
- Wage = the hourly wage on the employee's Tripletex employment, using the employment details that apply on the last day of the selected month **(call)**.
- Amount = hours × wage, rounded to two decimals.
- The calculation sits behind one object that asks "how is this employee paid?" (Tripletex `remunerationType`) and picks a rule. Only `HOURLY_WAGE` has a rule today. Every other type yields "Not handled yet". Adding fixed salary later is adding a rule.

### "Payout in Tripletex"

- Asks for confirmation showing employee, month, hours, wage and amount.
- Creates a payslip for that employee in Tripletex with one line: the hourly-wage salary type, count = hours, rate = wage.
- Records the payout in Stemplin with the hours, wage and amount that were sent, who sent it, when, and the Tripletex ids. The page shows these stored values afterwards, not live ones.
- At most one payout per user, organization and month, guaranteed by the database. Two admins clicking at once must not produce two payslips.
- The wage sent must be the wage shown. If it changed in Tripletex between rendering the page and clicking, refuse and ask the admin to reload **(call)**.
- If Tripletex rejects the request, show its message on the row. The row stays Ready so the admin can retry.
- If a payslip was created in Tripletex but adding the wage line fails, clean up the half-made run in Tripletex so a retry does not leave duplicates.
- **Unknown outcome (call).** If the request timed out or the connection dropped after the run was requested, or the cleanup itself failed, Stemplin cannot know whether a payslip exists. The row then gets a seventh status, "Check Tripletex", with no payout button. It offers two admin actions: "Mark as sent" (a payslip exists in Tripletex) and "Release" (none exists, the row returns to Ready). It never returns to Ready by itself.

### Which Tripletex salary run **(call)**

- Each payout creates its own salary run in Tripletex, containing that one employee. This is the simplest thing that works. Collecting several employees in one run is a later improvement.
- The run is dated in the month the admin clicks, since October's hours are normally paid in November. Its description names the hours month, for example "Timer oktober 2026 (Stemplin)".
- The run is created without Tripletex's default lines (`addDefaultSpecifications=false`), so it holds the hours line and the tax deduction only. Paying two hours months in the same pay month then never duplicates fixed additions or deductions. The accountant adds anything else in Tripletex.

### Which salary type **(call)**

- The connection settings page (`workspace/integrations`) gets a dropdown "Salary type for hourly pay", filled from the organization's salary types in Tripletex.
- It preselects the type named "Timelønn" when one exists.
- The Payroll page asks the admin to choose one before any payout is possible.

## Disconnecting and reconnecting **(call)**

- Disconnecting from Tripletex removes the locks for months that were never sent, after a confirmation that says so. Otherwise those months would stay locked with no page to unlock them from.
- Months that were sent stay locked for good, connected or not, and their payout records are kept.
- Connecting to a different Tripletex company than before (the company id differs) clears the employee links and the chosen salary type. Reconnecting to the same company keeps them.
- The "month before the connection" cutoff for the lock button follows the latest connection.

## What to keep, change and remove from the branch

Keep: `TripletexIntegration` and its encrypted token, the connect/disconnect screens and policy, `Tripletex::Client` (auth, request handling, error mapping), `Tripletex::Error`, `FakeTripletexApi`, the sidebar entry, the env variables, the locale files' connection strings.

Remove: `Tripletex::CreateOrders`, `Tripletex::ReportPdf`, the "send to Tripletex" report action and views, the print header changes made for the PDF, `clients.tripletex_customer_id` and the client form dropdown, `time_regs.invoiced_at`, the client methods `customers`, `vat_type_id`, `create_order`, `attach_to_order`, any gems added only for the PDF, and their tests and locale strings.

The branch is unmerged, so delete the unwanted migrations rather than adding reversing ones **(call)**.

## Tripletex API notes

Checked against the published spec (`https://tripletex.no/v2/openapi.json`, version 2.75.23) and exercised against the Tripletex test environment (`https://api-test.tripletex.tech/v2`) on 2026-11-11. The BETA salary-run endpoints work there; the deprecated `POST /salary/transaction` was not needed.

- **Employees:** `GET /employee?isInactive=false&fields=id,firstName,lastName,email,employeeNumber&count=1000`. `isInactive` is a query filter, not a field: asking for it in `fields` is a 422. `employeeNumber` can be `""`.
- **Wage:** one request covers many employees: `GET /employee?id=1,2,3&fields=id,employments(startDate,endDate,employmentDetails(date,remunerationType,hourlyWage))&count=1000` returns every employee's employments with all their details rows. Do not use the unfiltered `GET /employee/employment` list: in the test company it returned only the token owner's employment (with `employeeId=` it works, but that is one request per employee). There is no date filter: pick the employment with `startDate <= date` and `endDate` null or `>= date`, then its details row with the latest `date <= date`. `hourlyWage` is a number (e.g. `250.0`), `0.0` (not null) when unset; `remunerationType` is `NOT_CHOSEN` on a fresh employment.
- **Salary types:** `GET /salary/type?isInactive=false&fields=id,number,name&count=1000` (`isInactive` again only a filter). `number` is a string (`"2001"` = Timelønn). The test company has 150+ active types.
- **Create run:** `POST /salary/transaction/:createSalaryRun?year=2026&month=10&date=2026-11-11&description=...&addDefaultSpecifications=false` with JSON body `[employeeId]` → 201 `{ value: { id, date, year, month, isHistorical, paySlipsAvailableDate, payslips: [{ id }] } }`. The payslip id comes back in the same response.
- **Add line:** `PUT /salary/transaction/{id}/:addSpecification` with `{ payslip: { id }, salaryType: { id }, rate, count }` → 200 `{ value: { id, rate, count, amount, ... } }`. Tripletex computes `amount = rate × count` (250 × 12.33 = 3082.5).
- **Tax line:** even with `addDefaultSpecifications=false` the payslip gets a `6000 Skattetrekk` line, recalculated as lines are added (−1541.0 on 3082.5 in a company without tax cards). The payslip's `amount`/`grossAmount` read back as `0.0` while the run is open.
- **Delete:** `DELETE /salary/transaction/{id}` → 204, empty body. A later `GET` of it is 404 "Object not found".
- **Employee prerequisites:** `createSalaryRun` fails with 422 `employeeIds: Ansatt N kan ikke få lønn i perioden. Kontroller den ansattes fødselsdato, kommunen for arbeidsgiveravgift og at arbeidsforholdet tilhører en gyldig virksomhet.` unless the employee has a date of birth and the employment belongs to a division (virksomhet, with a municipality). Updating an employment also requires the employee's `dateOfBirth`. These surface through the normal validation-message error.
- **Errors:** the client raises `Tripletex::AccessError` (`tripletex.errors.salary_access`) on 401/403 from `/salary/*`, `/employee/employment*` and the wage request, and `Tripletex::UncertainError` when a POST/PUT/DELETE fails after the connection was opened (timeouts on reads stay `Tripletex::Error`). A 401/403 response itself was not reproduced live: the test key has full access.
- The employee token needs salary access in Tripletex and the company needs the salary module.

## Constraints

- Follow the repo's authorization rules: `authorize!` in every action, `authorized_scope` for every query, a policy per action. Payroll and unlock are admin-only. Members lock their own months only. Admins can lock for any member of their organization.
- All data is scoped to the current organization.
- All new text in both `en` and `nb`.
- Tests never call Tripletex. Extend `FakeTripletexApi`.
- Minitest with fixtures, matching the existing suite.

## Left to the builder

- Table and class names for locks and payouts, and how the lock rule is expressed on `TimeReg`.
- How Tripletex data is fetched and cached for the page (one nested `fields` request or several).
- Exact layout and copy, following the existing workspace pages and RubyUI components.
- How the "pending" state of an in-flight payout is represented to guarantee single sending.
- Which date decides "the month has ended" (server date is fine).
