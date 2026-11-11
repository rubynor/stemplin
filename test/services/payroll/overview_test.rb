require "test_helper"

class Payroll::OverviewTest < ActiveSupport::TestCase
  PayoutStub = Struct.new(:status, :hours, :rate, :amount)

  setup do
    @organization = organizations(:organization_one)
    @organization.create_tripletex_integration!(employee_token: "x")
    @admin = users(:organization_admin)
    @user = users(:organization_user)
    @period = Date.current.last_month.beginning_of_month
    @info = access_info_for(@user)
    @info.update!(tripletex_employee_id: 7)
    log(@user, 125)
    lock_for(@user)
    install_pay({ 7 => hourly(250) })
  end

  teardown { FakeTripletexApi.reset }

  def access_info_for(user)
    AccessInfo.find_or_create_by!(user: user, organization: @organization) { |i| i.role = :organization_user }
  end

  def hourly(wage) = { "remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal(wage.to_s) }

  def install_pay(pay, **opts)
    @fake = FakeTripletexApi.install(FakeTripletexApi.new(pay_details: pay, **opts))
  end

  def log(user, minutes, task: assigned_task(:task_1), date: @period + 3)
    user.time_regs.create!(assigned_task: task, minutes: minutes, date_worked: date)
  end

  def lock_for(user)
    TimeLock.create!(organization: @organization, user: user, locked_by: @admin, period: @period)
  end

  def row_for(user, overview = Payroll::Overview.new(organization: @organization, period: @period))
    overview.rows.find { |r| r.user == user }
  end

  def with_payout(payout)
    Payroll::Overview.class_eval { alias_method :__orig_payout_for, :payout_for; define_method(:payout_for) { |_u| payout } }
    yield
  ensure
    Payroll::Overview.class_eval { alias_method :payout_for, :__orig_payout_for; remove_method :__orig_payout_for }
  end

  test "ready with hours, rate and amount" do
    row = row_for(@user)
    assert_equal :ready, row.status
    assert_equal [ 125, BigDecimal("2.08"), BigDecimal("250"), BigDecimal("520.00") ], [ row.minutes, row.hours, row.rate, row.amount ]
    assert_equal @info, row.access_info
    assert row.lock
  end

  test "pay details are requested for the last day of the month" do
    row_for(@user)
    assert_equal [ { employee_ids: [ 7 ], on: @period.end_of_month } ], @fake.pay_details_calls
  end

  test "sent when the payout is sent, with the payout's figures" do
    with_payout(PayoutStub.new("sent", BigDecimal("2.00"), BigDecimal("200"), BigDecimal("400.00"))) do
      row = row_for(@user)
      assert_equal :sent, row.status
      assert_equal [ BigDecimal("2.00"), BigDecimal("200"), BigDecimal("400.00") ], [ row.hours, row.rate, row.amount ]
    end
  end

  test "unclear for an unclear or pending payout" do
    %w[unclear pending].each do |status|
      with_payout(PayoutStub.new(status, BigDecimal("2.00"), BigDecimal("200"), BigDecimal("400.00"))) do
        assert_equal :unclear, row_for(@user).status
      end
    end
  end

  test "no hours" do
    row = row_for(users(:joe))
    assert_equal :no_hours, row.status
    assert_equal 0, row.minutes
    assert_nil row.amount
  end

  test "not linked" do
    @info.update!(tripletex_employee_id: nil)
    row = row_for(@user)
    assert_equal :not_linked, row.status
    assert_nil row.amount
    assert_empty @fake.pay_details_calls
  end

  test "not locked shows preliminary rate and amount" do
    TimeLock.where(user: @user).delete_all
    row = row_for(@user)
    assert_equal :not_locked, row.status
    assert_equal BigDecimal("520.00"), row.amount
  end

  test "unsupported when not paid by the hour" do
    install_pay({ 7 => { "remunerationType" => "MONTHLY_WAGE", "hourlyWage" => nil } })
    row = row_for(@user)
    assert_equal :unsupported, row.status
    assert_nil row.amount
  end

  test "unsupported when the employee has no employment" do
    install_pay({})
    assert_equal :unsupported, row_for(@user).status
  end

  test "hours on a discarded project count" do
    task = assigned_task(:task_2)
    task.project.update_columns(discarded_at: Time.current)
    TimeLock.where(user: @user).delete_all
    log(@user, 60, task: task)
    lock_for(@user)
    assert_equal 185, row_for(@user).minutes
  end

  test "an archived member with hours appears, one without does not" do
    archived = access_info_for(users(:joe))
    archived.update_columns(archived_at: Time.current)
    assert_nil row_for(users(:joe))
    log(users(:joe), 30)
    assert_equal 30, row_for(users(:joe)).minutes
  end

  test "a spectator appears only with hours" do
    spectator = users(:organization_spectator)
    assert_nil row_for(spectator)
    log(spectator, 30)
    assert row_for(spectator)
  end

  test "a Tripletex error keeps hours and gives no ready row" do
    install_pay({ 7 => hourly(250) }, error: "Tripletex is down")
    overview = Payroll::Overview.new(organization: @organization, period: @period)
    row = row_for(@user, overview)
    assert_equal "Tripletex is down", overview.error
    assert_equal 125, row.minutes
    assert_equal BigDecimal("2.08"), row.hours
    assert_nil row.rate
    assert_nil row.amount
    assert overview.rows.none? { |r| r.status == :ready }
  end

  test "rows are sorted by name" do
    names = Payroll::Overview.new(organization: @organization, period: @period).rows.map { |r| (r.user.name.presence || r.user.email).downcase }
    assert_equal names.sort, names
  end
end
