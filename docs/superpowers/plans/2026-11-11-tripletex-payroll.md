# Tripletex Payroll Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let an admin send each hourly-paid team member's locked month from Stemplin to a Tripletex payslip with one click.

**Architecture:** Three pieces on top of the existing Tripletex connection: a `TimeLock` record that freezes a user's month (enforced on the `TimeReg` model), a `tripletex_employee_id` on `AccessInfo`, and a `PayrollPayout` record created by a service that talks to Tripletex. The Payroll page is a read model (`Payroll::Overview`) that combines Stemplin hours, locks, payouts and Tripletex pay details into rows with a status.

**Tech Stack:** Rails 8.1, PostgreSQL, ActionPolicy, Hotwire, Phlex/RubyUI, Minitest with fixtures, PaperTrail, `Net::HTTP` via the existing `Tripletex::Client`.

**Spec:** `docs/superpowers/specs/2026-11-11-tripletex-payroll-design.md`. Read it before any task. This plan does not repeat its behaviour rules.

## Global Constraints

- `authorize!` in every controller action, `authorized_scope` for every query, a policy rule per action.
- Every query is scoped to `current_user.current_organization`.
- Every new string exists in both `config/locales/tripletex.en.yml` and `config/locales/tripletex.nb.yml`, under `tripletex.payroll.*`, `tripletex.locks.*`, `tripletex.team_members.*`.
- Tests never call Tripletex. They use `FakeTripletexApi` (`test/support/fake_tripletex_api.rb`), reset in `teardown`.
- A period is always a `Date` on the first of the month. URLs carry it as `month=YYYY-MM`.
- Hours sent to Tripletex are `(minutes / 60.0).round(2)`. Amount is `(hours * wage).round(2)` using those rounded hours.
- Run `bin/rubocop -a` before each commit. Commit after each task.
- Fixture users: `users(:organization_admin)`, `users(:organization_user)`, `users(:organization_spectator)` all belong to `organizations(:organization_one)`.

## Review Focus

1. **Month boundaries.** An entry on the last day of a locked month is blocked and one on the first day of the next month is not. Moving an entry's date into or out of a locked month is blocked. (Task 3)
2. **Two organizations.** A lock in organization A does not block the same user's entries in organization B. (Task 3)
3. **Double submit.** Two payout requests for the same user and month produce one Tripletex run. (Task 8)
4. **Awkward employments.** An employee with two employments, an employment that ended before the month, or a details row dated after the month ends still gets the wage that applied on the month's last day, or "Not handled yet" when none did. (Task 2)
5. **Odd minute totals.** 125 minutes at 250.00 shows 2.08 hours and 520.00, and exactly those numbers are sent. (Task 7)

---

### Task 1: Bring in the branch and remove the invoicing integration

**Files:**
- Merge: `origin/feature/tripletex-integration` into the working branch (it sits directly on `main`, so it merges cleanly).
- Delete: `app/services/tripletex/create_orders.rb`, `app/services/tripletex/report_pdf.rb`, `app/views/reports/_send_to_tripletex.html.erb`, `app/views/reports/details/_print_header.html.erb`, `app/javascript/controllers/printed_at_controller.js`, `app/javascript/controllers/tripletex_customer_controller.js`, `db/migrate/20261110100100_add_tripletex_customer_id_to_clients.rb`, `db/migrate/20261110100200_add_invoiced_at_to_time_regs.rb`, `test/controllers/reports_send_to_tripletex_test.rb`, `test/services/tripletex/create_orders_test.rb`, `test/services/tripletex/report_pdf_test.rb`
- Revert to `main`'s version: `app/controllers/reports_controller.rb`, `app/controllers/workspace/clients_controller.rb`, `app/policies/report_policy.rb`, `app/models/time_reg.rb`, `app/views/reports/**`, `app/views/workspace/clients/_form.html.erb`, `app/views/api/v1/time_regs/_time_reg.json.jbuilder`, `app/assets/stylesheets/application.tailwind.css`, `test/controllers/workspace/clients_controller_test.rb`
- Modify: `Gemfile` (drop `prawn`, `prawn-table`), `config/routes.rb` (drop `send_to_tripletex_reports`), `app/javascript/controllers/index.js` (drop the two controllers), `app/services/tripletex/client.rb` (drop `customers`, `vat_type_id`, `create_order`, `attach_to_order`, and the `form:` multipart branch), `test/support/fake_tripletex_api.rb` and `test/services/tripletex/client_test.rb` (drop the same), both `tripletex.*.yml` files (drop `order`, `clients`, `reports`, `print`, `errors.vat_type_missing`; reword `integrations.description`, `integrations.disconnect_confirmation` and `setup.steps[1].body` for payroll: the key needs access to employees and salary), `db/schema.rb`

- [ ] **Step 1:** `git merge origin/feature/tripletex-integration`.
- [ ] **Step 2:** Apply the deletions, reverts (`git checkout main -- <path>`) and modifications above. Run `bundle install`.
- [ ] **Step 3:** `bin/rails db:drop db:create db:migrate` so `db/schema.rb` is regenerated without `clients.tripletex_customer_id` and `time_regs.invoiced_at`. `git diff main -- db/schema.rb` must show only the `tripletex_integrations` table and its foreign key.
- [ ] **Step 4:** `grep -rn "invoiced\|tripletex_customer\|create_order\|prawn\|send_to_tripletex" app config test lib Gemfile` returns nothing.
- [ ] **Step 5:** `bin/rake test` passes. `bin/rubocop` is clean.
- [ ] **Step 6:** Commit: "Strip the order/invoice parts from the Tripletex integration".

---

### Task 2: Prove the salary flow against Tripletex, then add the client methods

**Files:**
- Modify: `app/services/tripletex/client.rb`, `app/services/tripletex/error.rb`, `test/support/fake_tripletex_api.rb`, `test/services/tripletex/client_test.rb`, the spec's "Tripletex API notes" section
- Throwaway, not committed: `tmp/tripletex_spike.rb`

**Interfaces — produces (on `Tripletex::Client`, mirrored on `FakeTripletexApi`):**
- `employees -> Array<Hash>` each `{ "id", "firstName", "lastName", "email", "employeeNumber" }`, active only, sorted by name.
- `pay_details(employee_ids, on:) -> Hash{Integer => Hash|nil}` each value `{ "remunerationType" => String, "hourlyWage" => BigDecimal|nil }`, or `nil` when no employment covers `on`.
- `salary_types -> Array<Hash>` each `{ "id", "number", "name" }`, active only.
- `create_salary_run(employee_id:, year:, month:, date:, description:) -> { "transaction_id" => Integer, "payslip_id" => Integer }`
- `add_salary_line(transaction_id:, payslip_id:, salary_type_id:, rate:, count:) -> nil`
- `delete_salary_run(transaction_id) -> nil`
- `Tripletex::UncertainError < Tripletex::Error`: raised when a write request (`POST`/`PUT`/`DELETE`) fails with a timeout or connection error after it may have been sent.
- `Tripletex::AccessError < Tripletex::Error`: raised on 401/403 from `/salary/*` or `/employee/employment*`, message `tripletex.errors.salary_access`.
- `FakeTripletexApi.new(employees: [], pay_details: {}, salary_types: [], run_error: nil, line_error: nil, delete_error: nil, ...)` with readers `salary_runs`, `salary_lines`, `deleted_runs`. `run_error`/`line_error`/`delete_error` take an exception instance to raise.

- [ ] **Step 1: Get test credentials.** Ask Kasper for the Tripletex test consumer token and employee token (use the secret request tool, never chat). Set `TRIPLETEX_BASE_URL=https://api-test.tripletex.tech/v2` and `TRIPLETEX_CONSUMER_TOKEN` in the shell only.
- [ ] **Step 2: Spike.** In `tmp/tripletex_spike.rb`, using raw requests through `Tripletex::Client#request`, do in order: list employees; read one hourly employee's employments with nested details; list salary types; `POST /salary/transaction/:createSalaryRun?year=&month=&date=&description=&addDefaultSpecifications=false` with body `[employeeId]`; `PUT /salary/transaction/{id}/:addSpecification` with `{ payslip: { id: }, salaryType: { id: }, rate:, count: }`; `GET` the run back; `DELETE /salary/transaction/{id}`. Record for each: the exact request that worked and the response shape.
- [ ] **Step 3: Decide and write down.** If the BETA endpoints work, use them. If they are refused, repeat the spike with `POST /salary/transaction` (nested `payslips[].specifications[]`) and use that. Update the spec's API notes with what was observed, including whether one nested `fields=` request can return employments and details for all employees. If neither flow works, stop and report to Kasper.
- [ ] **Step 4: Write failing client tests** in `test/services/tripletex/client_test.rb`, in the file's existing stubbing style, one per method above, plus:

```ruby
test "pay_details picks the details row that applied on the given date" do
  # employment 2020-01-01..nil with details dated 2024-01-01 (hourlyWage 200),
  # 2026-06-01 (hourlyWage 250) and 2026-11-01 (hourlyWage 300)
  assert_equal BigDecimal("250"), client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7]["hourlyWage"]
end

test "pay_details is nil when the only employment ended before the date" do
  assert_nil client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7]
end

test "pay_details uses the employment that covers the date when there are two" do
  # ended employment (MONTHLY_WAGE) and current one (HOURLY_WAGE, 250)
  assert_equal "HOURLY_WAGE", client.pay_details([ 7 ], on: Date.new(2026, 10, 31))[7]["remunerationType"]
end

test "a timeout on a write raises UncertainError" do
  assert_raises(Tripletex::UncertainError) { client.create_salary_run(employee_id: 7, year: 2026, month: 11, date: Date.new(2026, 11, 11), description: "x") }
end

test "a 403 on a salary call raises AccessError" do
  assert_raises(Tripletex::AccessError) { client.salary_types }
end
```

- [ ] **Step 5:** Run `bin/rails test test/services/tripletex/client_test.rb`. Expected: the new tests fail with `NoMethodError`.
- [ ] **Step 6: Implement** the methods and errors with the requests proven in Step 2. Read timeouts on `GET` keep raising plain `Tripletex::Error`.
- [ ] **Step 7:** Extend `FakeTripletexApi` per the interface. `create_salary_run` returns ids starting at `transaction_id: 5001, payslip_id: 9001`.
- [ ] **Step 8:** `bin/rails test test/services/tripletex` passes. Delete `tmp/tripletex_spike.rb`.
- [ ] **Step 9:** Commit: "Add Tripletex client calls for employees, pay details and salary runs".

---

### Task 3: Month locks and their enforcement on time entries

**Files:**
- Create: `db/migrate/<ts>_create_time_locks.rb`, `app/models/time_lock.rb`, `test/models/time_lock_test.rb`
- Modify: `app/models/time_reg.rb`, `app/models/organization.rb` (`has_many :time_locks`), `test/models/time_reg_test.rb`, `config/locales/tripletex.{en,nb}.yml`

**Interfaces — produces:**
- Table `time_locks`: `organization_id` (fk, not null), `user_id` (fk, not null), `period` (date, not null), `locked_by_id` (fk to users, not null), timestamps. Unique index on `[organization_id, user_id, period]`.
- `TimeLock` with `has_paper_trail`, `belongs_to :organization, :user, :locked_by`.
- `TimeLock.locked?(organization_id:, user_id:, date:) -> Boolean`
- `TimeLock.for_period(date) -> relation` (normalises to the first of the month).
- `TimeLock#locked_by_other? -> Boolean`
- Validations on `TimeLock`: `period` is the first of a month; the month has ended (`period.end_of_month < Date.current`); the user has no running timer on an entry in that month and organization (`tripletex.locks.errors.timer_running`).
- `TimeReg#organization_id_for_lock -> Integer`: the organization through assigned task, project and client, ignoring soft-deletes on project and client.
- `TimeReg` refuses create, update, discard and destroy when `TimeLock.locked?` for its current `date_worked` or its previous `date_worked`. Error on `:base`: `tripletex.locks.errors.month_locked` with `month:` ("October 2026").

- [ ] **Step 1: Write failing tests.** In `test/models/time_lock_test.rb`: valid lock for last month; rejects the current month; rejects a mid-month `period`; rejects a second lock for the same user, organization and month; rejects when a timer is running in the month. In `test/models/time_reg_test.rb`, with a lock for `users(:organization_user)` in `organizations(:organization_one)` for last month (`last = Date.current.last_month`):

```ruby
test "cannot create an entry in a locked month" do
  reg = @user.time_regs.new(assigned_task: @task, minutes: 60, date_worked: last.end_of_month)
  assert_not reg.save
  assert_includes reg.errors[:base].first, I18n.l(last, format: "%B %Y")
end

test "can create an entry on the first day after a locked month" do
  assert @user.time_regs.new(assigned_task: @task, minutes: 60, date_worked: last.end_of_month + 1).save
end

test "cannot edit, move out of, move into, or discard an entry in a locked month" do
  assert_not @locked_reg.update(minutes: 5)
  assert_not @locked_reg.update(date_worked: Date.current)
  assert_not @open_reg.update(date_worked: last.beginning_of_month)
  assert_not @locked_reg.discard
  assert @locked_reg.reload.kept?
end

test "a lock in one organization does not block the user's entries in another" do
  # same user, assigned task belonging to organizations(:organization_two)
  assert @user.time_regs.new(assigned_task: @other_org_task, minutes: 60, date_worked: last.end_of_month).save
end

test "an entry on a since-deleted project is still protected" do
  @locked_reg.project.discard
  assert_not TimeReg.find(@locked_reg.id).update(minutes: 5)
end
```

- [ ] **Step 2:** Run `bin/rails test test/models/time_lock_test.rb test/models/time_reg_test.rb`. Expected: failures on missing `TimeLock`.
- [ ] **Step 3: Implement.** Migration and model as above. On `TimeReg`: a validation for create/update, plus `before_discard` and `before_destroy` callbacks that add the error and `throw :abort`. `discard` skips validations, so the callback is what protects deletion.
- [ ] **Step 4:** `grep -rn "update_all\|update_column\|insert_all\|TimeReg.import\|upsert" app lib` and list every hit that writes `time_regs`. Any that can touch a locked month must go through the model or check `TimeLock.locked?`. Add a test for each one changed.
- [ ] **Step 5:** Make deletion failures visible: `TimeRegsController#destroy` and `Api::V1::TimeRegsController#destroy` currently rescue `ActiveRecord::RecordNotDestroyed`. `discard!` raises `Discard::RecordNotDiscarded`. Rescue that too, web: flash the record's error and redirect back; API: 422 with the error. Add one controller test each in `test/controllers/time_regs_controller_test.rb` and `test/controllers/api/v1/time_regs_controller_test.rb`, plus one in `test/controllers/api/v1/timers_controller_test.rb` asserting 422 when toggling a timer on a locked entry.
- [ ] **Step 6:** `bin/rake test` passes.
- [ ] **Step 7:** Commit: "Add month locks that freeze a user's time entries".

---

### Task 4: Locking and unlocking from the UI

**Files:**
- Create: `app/controllers/time_locks_controller.rb`, `app/policies/time_lock_policy.rb`, `app/views/time_regs/_lock_month.html.erb`, `test/controllers/time_locks_controller_test.rb`
- Modify: `config/routes.rb` (`resources :time_locks, only: %i[create destroy]`), `app/models/time_lock.rb`, `app/controllers/time_regs_controller.rb` (`index`), `app/views/time_regs/_top_nav.html.erb`, `app/views/time_regs/_time_reg.html.erb`, `app/views/time_regs/_main.html.erb`, locale files

**Interfaces:**
- Consumes: `TimeLock`, `TimeLock.locked?` (Task 3).
- Produces:
  - `TimeLock.next_lockable_period(user:, organization:) -> Date|nil`: the oldest ended month, not before `integration.connected_at.to_date.last_month.beginning_of_month`, in which the user has kept entries in the organization and no lock. `nil` when the organization has no Tripletex integration. Until Task 6 adds `connected_at`, use `integration.created_at`.
  - `TimeLock.minutes_in(user:, organization:, period:) -> Integer` (counts entries on soft-deleted projects and clients).
  - `POST /time_locks` params `month=YYYY-MM`, optional `user_id`. `DELETE /time_locks/:id`. Both `redirect_back fallback_location: root_path` with a flash.
  - `TimeLockPolicy#create?`: the record's organization is the user's current one, and either the record is for the user and they are not a spectator, or the user is an organization admin. `#destroy?`: organization admin of the record's organization. `scope_for :relation`: locks in the current organization, all for admins, own for others.
  - Unlock is refused (flash `tripletex.locks.errors.already_sent`) when a payout exists for the lock. Until Task 8 adds `PayrollPayout`, leave a `TimeLock#sent?` method returning `false`; Task 8 fills it in.

- [ ] **Step 1: Write failing controller tests:** a member locks last month for themselves (creates a lock with `locked_by` = themselves); a member cannot lock for another user (`assert_redirected_to root_path`, no lock); an admin locks for another member (`locked_by` = admin); a spectator cannot lock; nobody can lock the current month; a member cannot unlock; an admin unlocks; an admin of another organization cannot unlock; `next_lockable_period` returns `nil` without an integration, the older month when two qualify, and skips months before the cutoff.
- [ ] **Step 2:** Run `bin/rails test test/controllers/time_locks_controller_test.rb`. Expected: routing errors.
- [ ] **Step 3: Implement** controller, policy and the two class methods.
- [ ] **Step 4: Start screen.** In `TimeRegsController#index` set `@lockable_period` and `@lockable_minutes`. Render `_lock_month` in `_top_nav`'s button row when `@lockable_period` is set: a `ButtonComponent` (variant `:outline`) posting to `time_locks_path(month:)` with `turbo_confirm` = `tripletex.locks.confirm` (`month:`, `hours:`), label `tripletex.locks.lock_button` ("Lock in hours for %{month}" / "Lås timer for %{month}").
- [ ] **Step 5: Locked days.** When `@chosen_date`'s month is locked for the current user and organization: hide the "Log time" button, and in `_time_reg` hide copy, timer, edit and delete controls; show a gray `RubyUI::Badge` with `tripletex.locks.locked`. Add controller tests asserting the button text appears when lockable and that the edit control is absent on a locked day.
- [ ] **Step 6:** `bin/rake test` passes.
- [ ] **Step 7:** Commit: "Let members lock a finished month from the start screen".

---

### Task 5: Link team members to Tripletex employees

**Files:**
- Create: `db/migrate/<ts>_add_tripletex_employee_id_to_access_infos.rb`
- Modify: `app/models/access_info.rb`, `app/controllers/workspace/team_members_controller.rb`, `app/views/workspace/team_members/_form.html.erb`, `app/views/workspace/team_members/edit_modal.turbo_stream.erb` (pass new locals), `test/controllers/workspace/team_members_controller_test.rb`, `test/models/access_info_test.rb`, locale files

**Interfaces:**
- Consumes: `Tripletex::Client#employees` (Task 2).
- Produces: `access_infos.tripletex_employee_id` (bigint, nullable), unique index on `[organization_id, tripletex_employee_id]` where not null, matching model validation (`tripletex.team_members.errors.employee_taken`). Param `user[tripletex_employee_id]` on `PATCH /workspace/team_members/:id`; blank clears the link.

- [ ] **Step 1: Write failing tests:** saving the dialog with `tripletex_employee_id: 7` stores it on the member's `AccessInfo` in the current organization; blank clears it; linking an employee already linked to another member re-renders the form with the error; the edit dialog lists the fake's employees; it preselects the employee whose email equals the member's (case-insensitive) when no link exists; with the fake raising, the dialog renders with `tripletex.team_members.unavailable` and other fields still save; without an integration the field is absent and the param is ignored.
- [ ] **Step 2:** Run `bin/rails test test/controllers/workspace/team_members_controller_test.rb`. Expected: failures.
- [ ] **Step 3: Implement.** Follow the removed client-dropdown pattern from the branch (`git show origin/feature/tripletex-integration:app/controllers/workspace/clients_controller.rb`): `tripletex_employees` / `tripletex_employees_error` helper methods, `Rails.cache.fetch([ "tripletex_employees", integration.id, integration.updated_at.to_i ], expires_in: 5.minutes)`. Option label: `"#{firstName} #{lastName} (#{employeeNumber})"`. Keep an already-linked id selectable when it is missing from the list, shown as `"#<id>"`.
- [ ] **Step 4:** `bin/rake test` passes.
- [ ] **Step 5:** Commit: "Link team members to Tripletex employees".

---

### Task 6: Salary type setting, and what connecting and disconnecting do

**Files:**
- Create: `db/migrate/<ts>_add_payroll_settings_to_tripletex_integrations.rb`
- Modify: `app/models/tripletex_integration.rb`, `app/controllers/workspace/tripletex_integrations_controller.rb`, `app/policies/workspace/tripletex_integration_policy.rb` (add `update`), `app/controllers/workspace/integrations_controller.rb`, `app/views/workspace/integrations/show.html.erb`, `config/routes.rb` (add `update` to `tripletex_integration`), `app/models/time_lock.rb` (cutoff uses `connected_at`), `test/controllers/workspace/tripletex_integrations_controller_test.rb`, `test/controllers/workspace/integrations_controller_test.rb`, locale files

**Interfaces:**
- Consumes: `Tripletex::Client#salary_types`, `#company` (Task 2); `TimeLock` (Task 3).
- Produces: `tripletex_integrations.hourly_salary_type_id` (bigint, nullable), `tripletex_integrations.connected_at` (datetime, not null, backfilled from `created_at`). `PATCH /workspace/integrations/tripletex` with `tripletex_integration[hourly_salary_type_id]`.

- [ ] **Step 1: Write failing tests:**
  - the integrations page lists the fake's salary types and preselects the one named "Timelønn" when none is stored;
  - `PATCH` stores the chosen id; members cannot;
  - connecting sets `connected_at` to now;
  - reconnecting with a token for the same `company_id` keeps `hourly_salary_type_id` and every `tripletex_employee_id`;
  - reconnecting with a different `company_id` clears both and resets `connected_at`;
  - disconnecting deletes locks that have no sent payout, keeps the others, and keeps `tripletex_employee_id` values.
- [ ] **Step 2:** Run both controller test files. Expected: failures.
- [ ] **Step 3: Implement.** The disconnect confirmation text states that unsent locks are released (`tripletex.integrations.disconnect_confirmation`). Until Task 8, "has a sent payout" is `TimeLock#sent?`.
- [ ] **Step 4:** `bin/rake test` passes.
- [ ] **Step 5:** Commit: "Choose the hourly salary type and define connect/disconnect behaviour".

---

### Task 7: Payroll calculation

**Files:**
- Create: `app/services/payroll/pay_rules.rb`, `app/services/payroll/pay_rules/hourly.rb`, `app/services/payroll/overview.rb`, `test/services/payroll/pay_rules_test.rb`, `test/services/payroll/overview_test.rb`

**Interfaces:**
- Consumes: `TimeLock`, `TimeLock.minutes_in` (Tasks 3, 4), `AccessInfo#tripletex_employee_id` (Task 5), `Tripletex::Client#pay_details` (Task 2).
- Produces:
  - `Payroll::PayRules.for(pay) -> rule|nil` where `pay` is a `pay_details` value. Returns `Payroll::PayRules::Hourly` for `"HOURLY_WAGE"` with a positive `hourlyWage`, `nil` otherwise. A registry hash keyed by `remunerationType`, so a fixed-salary rule is one new entry.
  - `Payroll::PayRules::Hourly.new(pay)` with `#rate -> BigDecimal`, `#count(minutes) -> BigDecimal` (hours, 2 decimals), `#amount(minutes) -> BigDecimal` (`count * rate`, 2 decimals).
  - `Payroll::Overview.new(organization:, period:)` with `#rows -> Array<Row>` and `#error -> String|nil`.
  - `Row` (a `Data`): `user`, `access_info`, `minutes`, `hours`, `rate`, `amount`, `status`, `lock`, `payout`. `status` is one of `:not_linked, :not_locked, :unsupported, :ready, :sent, :unclear, :no_hours`.
  - Status precedence: a payout with status `sent` → `:sent`; payout `unclear` or `pending` → `:unclear`; zero minutes → `:no_hours`; no `tripletex_employee_id` → `:not_linked`; no lock → `:not_locked`; no pay rule → `:unsupported`; else `:ready`.
  - Row set: unarchived non-spectator members, plus any member (archived included) with minutes in the period. Sorted by name.
  - For `:sent`/`:unclear` rows, `hours`, `rate` and `amount` come from the payout record. Until Task 8, treat payout as always `nil` behind one private method.
  - When `pay_details` raises `Tripletex::Error`: `error` is the message, every row keeps its minutes, `rate`/`amount` are `nil`, and no row is `:ready`.

- [ ] **Step 1: Write failing tests.** `pay_rules_test.rb`:

```ruby
test "125 minutes at 250.00 is 2.08 hours and 520.00" do
  rule = Payroll::PayRules.for("remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal("250"))
  assert_equal BigDecimal("2.08"), rule.count(125)
  assert_equal BigDecimal("520.00"), rule.amount(125)
end

test "monthly wage, missing wage and nil pay have no rule" do
  assert_nil Payroll::PayRules.for("remunerationType" => "MONTHLY_WAGE", "hourlyWage" => nil)
  assert_nil Payroll::PayRules.for("remunerationType" => "HOURLY_WAGE", "hourlyWage" => nil)
  assert_nil Payroll::PayRules.for(nil)
end
```

`overview_test.rb`: one test per status in the precedence list; pay details are requested with `on:` = the period's last day; hours on a discarded project count; an archived member with hours appears and one without does not; a spectator without hours does not appear; a Tripletex error leaves hours visible and no `:ready` row.
- [ ] **Step 2:** Run `bin/rails test test/services/payroll`. Expected: `NameError`.
- [ ] **Step 3: Implement.** One grouped minutes query for all users, one `pay_details` call for all linked employee ids.
- [ ] **Step 4:** `bin/rails test test/services/payroll` passes.
- [ ] **Step 5:** Commit: "Add payroll calculation and overview".

---

### Task 8: Payouts

**Files:**
- Create: `db/migrate/<ts>_create_payroll_payouts.rb`, `app/models/payroll_payout.rb`, `app/services/payroll/send_payout.rb`, `app/services/payroll/error.rb`, `test/models/payroll_payout_test.rb`, `test/services/payroll/send_payout_test.rb`
- Modify: `app/models/time_lock.rb` (`sent?`), `app/services/payroll/overview.rb` (real payouts), `app/models/organization.rb` (`has_many :payroll_payouts`)

**Interfaces:**
- Consumes: Tasks 2, 3, 6, 7.
- Produces:
  - Table `payroll_payouts`: `organization_id`, `user_id`, `period` (date), `status` (integer, default 0), `minutes` (integer), `hours` decimal(8,2), `hourly_wage` decimal(12,2), `amount` decimal(12,2), `tripletex_employee_id` bigint, `tripletex_transaction_id` bigint null, `tripletex_payslip_id` bigint null, `sent_by_id` (fk users), `sent_at` datetime null, `error_message` text null, timestamps. Unique index on `[organization_id, user_id, period]`.
  - `PayrollPayout` with `enum :status, { pending: 0, sent: 1, unclear: 2 }`, `has_paper_trail`.
  - `PayrollPayout#mark_sent!(by:)` (only from `unclear`/`pending`) and `#release!` (destroys; only from `unclear`/`pending`).
  - `TimeLock#sent? -> Boolean`: a payout of any status exists for the lock's organization, user and period.
  - `Payroll::SendPayout.new(organization:, user:, period:, sent_by:, expected_rate:).call -> PayrollPayout` (status `sent`). Raises `Payroll::Error` (message is user-facing) for every refusal and for Tripletex rejections.
  - Tripletex run: `year`/`month`/`date` = `Date.current`; `description` = `tripletex.payroll.run_description` with the hours month, in Norwegian regardless of the admin's locale ("Timer oktober 2026 (Stemplin)").

**Sequence inside `call`** (this ordering is what prevents double payment):
1. Refuse unless: integration present, `hourly_salary_type_id` set, member linked, lock exists, minutes positive.
2. Fetch pay details fresh (no cache). Refuse if there is no pay rule. Refuse with `tripletex.payroll.errors.wage_changed` if `rule.rate != expected_rate`.
3. Insert the payout as `pending` with the figures. A `RecordNotUnique` here means another request got there first: raise `Payroll::Error` (`tripletex.payroll.errors.already_sent`). This insert is committed before any Tripletex call.
4. `create_salary_run`. On `Tripletex::UncertainError`: set `unclear`, store the message, raise `Payroll::Error`. On any other `Tripletex::Error`: destroy the payout, raise.
5. Store the transaction and payslip ids. `add_salary_line`. On any `Tripletex::Error`: try `delete_salary_run`; if that succeeds destroy the payout, otherwise set `unclear`; raise either way.
6. Set `sent`, `sent_at`.

- [ ] **Step 1: Write failing tests** in `send_payout_test.rb`, each with a member who has 125 minutes last month, a lock, employee id 7, salary type 31, fake pay `HOURLY_WAGE` 250:

```ruby
test "sends one run with one line and records it" do
  payout = service.call
  assert payout.sent?
  assert_equal [ BigDecimal("2.08"), BigDecimal("250"), BigDecimal("520.00") ], [ payout.hours, payout.hourly_wage, payout.amount ]
  assert_equal 1, @fake.salary_runs.size
  assert_equal({ transaction_id: 5001, payslip_id: 9001, salary_type_id: 31, rate: BigDecimal("250"), count: BigDecimal("2.08") }, @fake.salary_lines.first)
  assert_equal "Timer #{I18n.l(@period, format: '%B %Y', locale: :nb)} (Stemplin)", @fake.salary_runs.first[:description]
end

test "a second call does not create a second run" do
  service.call
  assert_raises(Payroll::Error) { service.call }
  assert_equal 1, @fake.salary_runs.size
end

test "refuses when the wage changed since the page was shown" do
  assert_raises(Payroll::Error) { service(expected_rate: BigDecimal("240")).call }
  assert_empty @fake.salary_runs
  assert_equal 0, PayrollPayout.count
end

test "a rejected run leaves no payout so the admin can retry" do
  @fake = install(run_error: Tripletex::Error.new("nope"))
  assert_raises(Payroll::Error) { service.call }
  assert_equal 0, PayrollPayout.count
end

test "a timed-out run is left unclear and blocks a retry" do
  @fake = install(run_error: Tripletex::UncertainError.new("timeout"))
  assert_raises(Payroll::Error) { service.call }
  assert PayrollPayout.last.unclear?
  assert_raises(Payroll::Error) { service.call }
end

test "a failed line deletes the run and leaves no payout" do
  @fake = install(line_error: Tripletex::Error.new("bad type"))
  assert_raises(Payroll::Error) { service.call }
  assert_equal [ 5001 ], @fake.deleted_runs
  assert_equal 0, PayrollPayout.count
end

test "a failed line whose cleanup also fails is left unclear" do
  @fake = install(line_error: Tripletex::Error.new("bad type"), delete_error: Tripletex::Error.new("no"))
  assert_raises(Payroll::Error) { service.call }
  assert PayrollPayout.last.unclear?
end
```

Plus one refusal test each for: not linked, not locked, no salary type chosen, zero minutes, monthly-wage employee. In `payroll_payout_test.rb`: the unique index; `release!` refuses a `sent` payout; `TimeLock#sent?`; a lock with a payout cannot be destroyed through `TimeLocksController` (add to that controller's test).
- [ ] **Step 2:** Run `bin/rails test test/services/payroll/send_payout_test.rb test/models/payroll_payout_test.rb`. Expected: `NameError`.
- [ ] **Step 3: Implement.** Wire real payouts into `Payroll::Overview` and add an overview test for `:sent` and `:unclear` rows showing stored figures.
- [ ] **Step 4:** `bin/rake test` passes.
- [ ] **Step 5:** Commit: "Send payouts to Tripletex as salary runs".

---

### Task 9: The Payroll page

**Files:**
- Create: `app/controllers/workspace/payroll_controller.rb`, `app/controllers/workspace/payroll_payouts_controller.rb`, `app/policies/workspace/payroll_policy.rb`, `app/policies/workspace/payroll_payout_policy.rb`, `app/views/workspace/payroll/show.html.erb`, `app/views/workspace/payroll/_row.html.erb`, `test/controllers/workspace/payroll_controller_test.rb`, `test/controllers/workspace/payroll_payouts_controller_test.rb`, `test/system/payroll_test.rb`
- Modify: `config/routes.rb`, `app/views/workspace/_sidenav.html.erb`, locale files

**Interfaces:**
- Consumes: `Payroll::Overview` (Task 7), `Payroll::SendPayout`, `PayrollPayout#mark_sent!`/`#release!` (Task 8), `TimeLocksController` (Task 4), the team member edit dialog (Task 5).
- Produces, inside `namespace :workspace`:
  - `resource :payroll, only: :show, controller: "payroll"` → `GET /workspace/payroll?month=YYYY-MM`. Default month: last month. An unparseable `month` falls back to the default.
  - `resources :payroll_payouts, only: :create do member { patch :mark_sent; delete :release } end`. `create` params: `user_id`, `month`, `expected_rate`.
  - `Workspace::PayrollPolicy#show?` and `Workspace::PayrollPayoutPolicy` (`create?`, `mark_sent?`, `release?`, relation scope): organization admin, current organization has a Tripletex integration, record in the current organization.

- [ ] **Step 1: Write failing controller tests.** `payroll_controller_test.rb`: admin sees a row per expected member with hours; defaults to last month; `month=2026-10` selects October; members and spectators are redirected to `root_path`; an admin without an integration is redirected to `workspace_integrations_path`; a `:ready` row has a payout button and a `:not_locked` row has "Lock for employee" and no payout button; with no salary type chosen the page shows `tripletex.payroll.choose_salary_type` and no payout buttons; with the fake raising, hours show, the error shows once, no payout buttons. `payroll_payouts_controller_test.rb`: create sends and redirects to the same month with a success flash; a `Payroll::Error` becomes an error flash and no payout; a member cannot create; an admin cannot create for a user of another organization; `mark_sent` and `release` work on an unclear payout and are refused for members and for other organizations' admins.
- [ ] **Step 2:** Run both files. Expected: routing errors.
- [ ] **Step 3: Implement controllers and policies.** `PayrollPayoutsController#create` finds the user through `authorized_scope(User, type: :relation)` including archived members of the current organization.
- [ ] **Step 4: Build the view** on the `workspace` layout, matching `workspace/team_members/index.html.erb`. Month picker: previous/next links around the month name, like the week stepper in `time_regs/_top_nav`. Columns and per-status actions exactly as the spec's status table, with `:unclear` showing "Check Tripletex", the stored error, and "Mark as sent" / "Release" buttons. Payout button: `turbo_confirm` = `tripletex.payroll.confirm` (`name:`, `month:`, `hours:`, `rate:`, `amount:`), and it carries `expected_rate`. "Lock for employee" posts to `time_locks_path(user_id:, month:)` with a confirm naming the employee, month and hours. "Unlock" deletes `time_lock_path(lock)`. "Link" opens the team member edit dialog. Show "locked by %{name}" when `lock.locked_by_other?`. Money uses the organization's currency formatting helper already used in reports.
- [ ] **Step 5: Sidebar.** Add "Payroll" / "Lønn" (`tripletex.payroll.title`) to `workspace/_sidenav` after team members, only when `current_user.organization_admin?` and the organization has an integration.
- [ ] **Step 6: System test** in `test/system/payroll_test.rb`: admin opens Payroll for last month, locks for a member, clicks "Payout in Tripletex", accepts the confirm, sees the row as sent with the date and no button; `@fake.salary_runs.size == 1`.
- [ ] **Step 7:** `bin/rake test` and `bin/rails test:system` pass.
- [ ] **Step 8:** Commit: "Add the Payroll page".

---

### Task 10: Final checks

- [ ] **Step 1: Locale parity.** Every key under `tripletex.` exists in both files: `ruby -ryaml -e 'f=->(h,p=""){h.flat_map{|k,v| v.is_a?(Hash) ? f.(v,"#{p}#{k}.") : ["#{p}#{k}"]}}; a=f.(YAML.load_file("config/locales/tripletex.en.yml")["en"]); b=f.(YAML.load_file("config/locales/tripletex.nb.yml")["nb"]); p a-b, b-a'` prints `[]` twice.
- [ ] **Step 2:** `bin/rake test`, `bin/rails test:system`, `bin/rubocop` all clean.
- [ ] **Step 3: Live pass against the Tripletex test account** with `bin/dev`: connect, choose the salary type, link a member, log hours last month, lock, pay out, then confirm in the Tripletex test UI that the run exists with one line of the right count and rate plus tax. Try the second click (refused) and an unlock after sending (refused). Report anything that differs from the spec to Kasper before opening a PR.
- [ ] **Step 4:** Commit any fixes. Do not push or open a PR until Kasper asks.
