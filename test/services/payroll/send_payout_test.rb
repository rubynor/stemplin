require "test_helper"

class Payroll::SendPayoutTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:organization_one)
    @integration = @organization.create_tripletex_integration!(employee_token: "x", hourly_salary_type_id: 31)
    @admin = users(:organization_admin)
    @user = users(:organization_user)
    @period = Date.current.last_month.beginning_of_month
    @info = @user.access_info(@organization)
    @info.update!(tripletex_employee_id: 7)
    @user.time_regs.create!(assigned_task: assigned_task(:task_1), minutes: 125, date_worked: @period + 3)
    @lock = TimeLock.create!(organization: @organization, user: @user, locked_by: @admin, period: @period)
    @fake = install
  end

  teardown { FakeTripletexApi.reset }

  def install(pay: { 7 => { "remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal("250") } }, **opts)
    FakeTripletexApi.install(FakeTripletexApi.new(pay_details: pay, **opts))
  end

  def service(expected_rate: BigDecimal("250"), user: @user, period: @period)
    Payroll::SendPayout.new(organization: @organization, user: user, period: period, sent_by: @admin, expected_rate: expected_rate)
  end

  def assert_refused(key, &block)
    error = assert_raises(Payroll::Error, &block)
    assert_equal I18n.t("tripletex.payroll.errors.#{key}"), error.message
    assert_empty @fake.salary_runs
    assert_equal 0, PayrollPayout.count
  end

  test "sends one run with one line and records it" do
    payout = service.call
    assert payout.sent?
    assert_equal [ BigDecimal("2.08"), BigDecimal("250"), BigDecimal("520.00") ], [ payout.hours, payout.hourly_wage, payout.amount ]
    assert_equal 1, @fake.salary_runs.size
    assert_equal({ "transaction_id" => 5001, "payslip_id" => 9001, "salary_type_id" => 31, "rate" => BigDecimal("250"), "count" => BigDecimal("2.08") }, @fake.salary_lines.first)
  end

  test "the run description names the month in lowercase Norwegian" do
    travel_to Date.new(2026, 11, 15) do
      period = Date.new(2026, 10, 1)
      TimeLock.where(user: @user).delete_all
      @user.time_regs.create!(assigned_task: assigned_task(:task_1), minutes: 60, date_worked: Date.new(2026, 10, 5))
      TimeLock.create!(organization: @organization, user: @user, locked_by: @admin, period: period)
      I18n.with_locale(:en) { service(period: period).call }
      assert_equal "Timer oktober 2026 (Stemplin)", @fake.salary_runs.first["description"]
    end
  end

  test "records who sent it, when, the minutes and the Tripletex ids" do
    freeze_time do
      payout = service.call.reload
      assert_equal [ @organization, @user, @period, @admin, Time.current ], [ payout.organization, payout.user, payout.period, payout.sent_by, payout.sent_at ]
      assert_equal [ 125, 7, 5001, 9001 ], [ payout.minutes, payout.tripletex_employee_id, payout.tripletex_transaction_id, payout.tripletex_payslip_id ]
      assert_nil payout.error_message
    end
  end

  test "the run is dated today for the employee, described in Norwegian whatever the locale" do
    I18n.with_locale(:en) { service.call }
    run = @fake.salary_runs.first
    assert_equal [ 7, Date.current.year, Date.current.month, Date.current ], run.values_at("employee_id", "year", "month", "date")
  end

  test "pay details are fetched fresh for the last day of the month" do
    service.call
    assert_equal [ { employee_ids: [ 7 ], on: @period.end_of_month } ], @fake.pay_details_calls
  end

  test "a second call does not create a second run" do
    service.call
    assert_raises(Payroll::Error) { service.call }
    assert_equal 1, @fake.salary_runs.size
  end

  test "an existing payout is refused by the database before Tripletex is called" do
    PayrollPayout.create!(organization: @organization, user: @user, period: @period, status: :unclear, minutes: 125, hours: 2.08,
                          hourly_wage: 250, amount: 520, tripletex_employee_id: 7, sent_by: @admin)
    error = assert_raises(Payroll::Error) { service.call }
    assert_equal I18n.t("tripletex.payroll.errors.already_sent"), error.message
    assert_empty @fake.salary_runs
  end

  test "refuses when the wage changed since the page was shown" do
    assert_raises(Payroll::Error) { service(expected_rate: BigDecimal("240")).call }
    assert_empty @fake.salary_runs
    assert_equal 0, PayrollPayout.count
  end

  test "an equal wage in another BigDecimal form is accepted" do
    assert service(expected_rate: BigDecimal("250.00")).call.sent?
  end

  test "refuses a missing expected wage" do
    assert_refused(:wage_changed) { service(expected_rate: nil).call }
  end

  test "a rejected run leaves no payout so the admin can retry" do
    @fake = install(run_error: Tripletex::Error.new("nope"))
    error = assert_raises(Payroll::Error) { service.call }
    assert_includes error.message, "nope"
    assert_equal 0, PayrollPayout.count
  end

  test "a timed-out run is left unclear and blocks a retry" do
    @fake = install(run_error: Tripletex::UncertainError.new("timeout"))
    assert_raises(Payroll::Error) { service.call }
    assert PayrollPayout.last.unclear?
    assert_equal "timeout", PayrollPayout.last.error_message
    assert_raises(Payroll::Error) { service.call }
  end

  test "a failed line deletes the run and leaves no payout" do
    @fake = install(line_error: Tripletex::Error.new("bad type"))
    error = assert_raises(Payroll::Error) { service.call }
    assert_includes error.message, "bad type"
    assert_equal [ 5001 ], @fake.deleted_runs
    assert_equal 0, PayrollPayout.count
  end

  test "a failed line whose cleanup also fails is left unclear" do
    @fake = install(line_error: Tripletex::Error.new("bad type"), delete_error: Tripletex::Error.new("no"))
    assert_raises(Payroll::Error) { service.call }
    assert PayrollPayout.last.unclear?
    assert_equal [ 5001, 9001 ], [ PayrollPayout.last.tripletex_transaction_id, PayrollPayout.last.tripletex_payslip_id ]
  end

  test "a timed-out line whose run is deleted leaves no payout" do
    @fake = install(line_error: Tripletex::UncertainError.new("timeout"))
    assert_raises(Payroll::Error) { service.call }
    assert_equal [ 5001 ], @fake.deleted_runs
    assert_equal 0, PayrollPayout.count
  end

  test "a failed line whose cleanup times out is left unclear" do
    @fake = install(line_error: Tripletex::Error.new("bad type"), delete_error: Tripletex::UncertainError.new("timeout"))
    assert_raises(Payroll::Error) { service.call }
    assert PayrollPayout.last.unclear?
  end

  test "an unexpected error after the run was requested leaves the payout unclear" do
    @fake = install
    @fake.define_singleton_method(:add_salary_line) { |**| raise ArgumentError, "boom" }
    @fake.define_singleton_method(:delete_salary_run) { |_id| raise "should not try cleanup after a bug" }
    error = assert_raises(Payroll::Error) { service.call }
    assert_includes error.message, "boom"
    assert PayrollPayout.last.unclear?
    assert_equal "boom", PayrollPayout.last.error_message
  end

  test "an unexpected error raised by the run request itself leaves the payout unclear" do
    @fake = install(run_error: RuntimeError.new("boom"))
    assert_raises(Payroll::Error) { service.call }
    assert PayrollPayout.last.unclear?
  end

  test "refuses a wage with more than two decimals before anything is stored" do
    @fake = install(pay: { 7 => { "remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal("250.125") } })
    assert_refused(:wage_precision) { service(expected_rate: BigDecimal("250.125")).call }
  end

  # An admin can release a pending payout once it is older than PayrollPayout::IN_FLIGHT_FOR. If that happens
  # while the send is still running, a run may exist in Tripletex, so a blocking record must be put back.
  def release_during(method)
    payout_destroyed = false
    @fake.define_singleton_method(method) do |**args|
      PayrollPayout.last.destroy!
      payout_destroyed = true
      super(**args)
    end
    yield
    assert payout_destroyed
  end

  test "a payout released while the run is created is restored as unclear" do
    release_during(:create_salary_run) do
      error = assert_raises(Payroll::Error) { service.call }
      assert_equal I18n.t("tripletex.payroll.errors.released"), error.message
    end
    payout = PayrollPayout.sole
    assert payout.unclear?
    assert_equal [ @organization, @user, @period, 125, BigDecimal("2.08"), BigDecimal("250"), BigDecimal("520") ],
                 [ payout.organization, payout.user, payout.period, payout.minutes, payout.hours, payout.hourly_wage, payout.amount ]
    assert_equal [ 5001, 9001 ], [ payout.tripletex_transaction_id, payout.tripletex_payslip_id ]
    assert_equal I18n.t("tripletex.payroll.errors.released"), payout.error_message
    assert_empty @fake.salary_lines
  end

  test "a payout released while the line is added is restored as unclear" do
    release_during(:add_salary_line) do
      assert_raises(Payroll::Error) { service.call }
    end
    payout = PayrollPayout.sole
    assert payout.unclear?
    assert_equal [ 5001, 9001 ], [ payout.tripletex_transaction_id, payout.tripletex_payslip_id ]
    assert_equal 1, @fake.salary_lines.size
  end

  test "a payout released before a timed-out run is marked unclear is restored without ids" do
    @fake = install(run_error: Tripletex::UncertainError.new("timeout"))
    @fake.define_singleton_method(:create_salary_run) { |**| PayrollPayout.last.destroy! && raise(Tripletex::UncertainError, "timeout") }
    assert_raises(Payroll::Error) { service.call }
    payout = PayrollPayout.sole
    assert payout.unclear?
    assert_nil payout.tripletex_transaction_id
  end

  test "a payout marked sent by an admin while the send runs is put back to unclear" do
    @fake.define_singleton_method(:add_salary_line) do |**args|
      PayrollPayout.last.update_columns(status: PayrollPayout.statuses[:sent])
      super(**args)
    end
    assert_raises(Payroll::Error) { service.call }
    assert PayrollPayout.sole.unclear?
  end

  test "a released payout replaced by a new attempt raises and is logged" do
    admin = @admin
    @fake.define_singleton_method(:create_salary_run) do |**args|
      released = PayrollPayout.last
      released.destroy!
      PayrollPayout.create!(released.attributes.except("id", "created_at", "updated_at").merge("status" => "pending", "sent_by_id" => admin.id))
      super(**args)
    end
    log = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(log).tap { |logger| logger.formatter = ->(severity, *, message) { "#{severity} #{message}\n" } }
    begin
      error = assert_raises(Payroll::Error) { service.call }
    ensure
      Rails.logger = original_logger
    end
    assert_equal I18n.t("tripletex.payroll.errors.released_conflict"), error.message
    assert PayrollPayout.sole.pending?
    logged = log.string.lines.grep(/\AERROR/)
    assert_equal 1, logged.size
    [ "organization #{@organization.id}", "user #{@user.id}", "period #{@period.iso8601}", "transaction 5001" ].each do |part|
      assert_includes logged.first, part
    end
  end

  test "refuses when not connected" do
    @integration.destroy!
    @organization.reload
    assert_refused(:not_connected) { service.call }
  end

  test "refuses when no salary type is chosen" do
    @integration.update!(hourly_salary_type_id: nil)
    assert_refused(:no_salary_type) { service.call }
  end

  test "refuses when the member is not linked" do
    @info.update!(tripletex_employee_id: nil)
    assert_refused(:not_linked) { service.call }
  end

  test "refuses a user who is not a member of the organization" do
    assert_refused(:not_linked) { service(user: users(:user_wo_access_info)).call }
  end

  test "an archived member can still be paid" do
    @info.update_columns(archived_at: Time.current)
    assert service.call.sent?
  end

  test "refuses when the month is not locked" do
    @lock.delete
    assert_refused(:not_locked) { service.call }
  end

  test "refuses when there are no hours" do
    @lock.delete
    @user.time_regs.where(date_worked: @period..@period.end_of_month).delete_all
    TimeLock.create!(organization: @organization, user: @user, locked_by: @admin, period: @period)
    assert_refused(:no_hours) { service.call }
  end

  test "refuses an employee who is not paid by the hour" do
    @fake = install(pay: { 7 => { "remunerationType" => "MONTHLY_WAGE", "hourlyWage" => BigDecimal("0") } })
    assert_refused(:unsupported) { service.call }
  end

  test "refuses when the wage cannot be read" do
    @fake = install(error: "down")
    error = assert_raises(Payroll::Error) { service.call }
    assert_includes error.message, "down"
    assert_equal 0, PayrollPayout.count
  end

  test "a sent month cannot be unlocked" do
    service.call
    assert @lock.reload.sent?
    assert_not @lock.destroy
    assert TimeLock.exists?(@lock.id)
  end
end
