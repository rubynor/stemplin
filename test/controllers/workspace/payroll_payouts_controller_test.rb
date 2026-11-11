require "test_helper"

module Workspace
  class PayrollPayoutsControllerTest < ActionController::TestCase
    setup do
      @organization = organizations(:organization_one)
      @admin = users(:organization_admin)
      @member = users(:organization_user)
      @organization.create_tripletex_integration!(employee_token: "x", hourly_salary_type_id: 31)
      @period = Date.current.last_month.beginning_of_month
      @month = @period.strftime("%Y-%m")
      @member.access_info(@organization).update!(tripletex_employee_id: 7)
      @member.time_regs.create!(assigned_task: assigned_task(:task_1), minutes: 125, date_worked: @period + 3)
      TimeLock.create!(organization: @organization, user: @member, locked_by: @admin, period: @period)
      @fake = FakeTripletexApi.install(FakeTripletexApi.new(pay_details: { 7 => { "remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal("250") } }))
    end

    teardown { FakeTripletexApi.reset }

    def unclear_payout(user: @member, organization: @organization)
      PayrollPayout.create!(organization: organization, user: user, period: @period, sent_by: @admin, status: :unclear, error_message: "x",
                            minutes: 125, hours: 2.08, hourly_wage: 250, amount: 520, tripletex_employee_id: 7, created_at: 1.hour.ago)
    end

    def create_payout(params = {})
      post :create, params: { user_id: @member.id, month: @month, expected_rate: "250.0", expected_minutes: "125" }.merge(params)
    end

    test "create sends the payout and redirects to the same month" do
      sign_in @admin
      assert_difference -> { PayrollPayout.sent.count }, 1 do
        create_payout
      end
      assert_redirected_to workspace_payroll_path(month: @month)
      assert flash[:success].present?
      assert_equal 1, @fake.salary_runs.size
    end

    test "a service error becomes an error flash and no payout" do
      sign_in @admin
      @fake = FakeTripletexApi.install(FakeTripletexApi.new(pay_details: { 7 => { "remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal("300") } }))
      assert_no_difference -> { PayrollPayout.count } do
        create_payout
      end
      assert_redirected_to workspace_payroll_path(month: @month)
      assert_equal I18n.t("tripletex.payroll.errors.wage_changed"), flash[:error]
    end

    test "a missing or unparseable rate is refused without calling the service" do
      sign_in @admin
      [ {}, { expected_rate: "abc" } ].each do |extra|
        post :create, params: { user_id: @member.id, month: @month, expected_minutes: "125" }.merge(extra)
        assert_redirected_to workspace_payroll_path(month: @month)
        assert_equal I18n.t("tripletex.payroll.errors.rate_missing"), flash[:error]
      end
      assert_equal 0, PayrollPayout.count
      assert_empty @fake.pay_details_calls
    end

    test "a missing or unparseable minutes count is refused without calling the service" do
      sign_in @admin
      [ { expected_minutes: nil }, { expected_minutes: "abc" }, { expected_minutes: "12.5" } ].each do |extra|
        create_payout(extra)
        assert_redirected_to workspace_payroll_path(month: @month)
        assert_equal I18n.t("tripletex.payroll.errors.hours_missing"), flash[:error]
      end
      assert_equal 0, PayrollPayout.count
      assert_empty @fake.pay_details_calls
    end

    test "hours that changed since the page was shown are refused" do
      sign_in @admin
      assert_no_difference -> { PayrollPayout.count } do
        create_payout(expected_minutes: "120")
      end
      assert_redirected_to workspace_payroll_path(month: @month)
      assert_equal I18n.t("tripletex.payroll.errors.hours_changed"), flash[:error]
      assert_empty @fake.salary_runs
    end

    test "a missing or unparseable month is refused without calling the service" do
      sign_in @admin
      [ { month: nil }, { month: "nonsense" } ].each do |extra|
        create_payout(extra)
        assert_redirected_to workspace_payroll_path
        assert_equal I18n.t("tripletex.payroll.errors.month_missing"), flash[:error]
      end
      assert_equal 0, PayrollPayout.count
      assert_empty @fake.pay_details_calls
    end

    test "a member cannot create" do
      sign_in @member
      assert_no_difference -> { PayrollPayout.count } do
        create_payout
      end
      assert_redirected_to root_path
      assert_empty @fake.salary_runs
    end

    test "an admin cannot create for a user of another organization" do
      sign_in @admin
      assert_no_difference -> { PayrollPayout.count } do
        create_payout(user_id: users(:customer_member).id)
      end
      assert_redirected_to root_path
      assert_empty @fake.salary_runs
    end

    test "an admin can pay an archived member" do
      @member.access_info(@organization).archive
      sign_in @admin
      assert_difference -> { PayrollPayout.sent.count }, 1 do
        create_payout
      end
    end

    test "mark_sent and release work on an unclear payout" do
      sign_in @admin
      payout = unclear_payout
      patch :mark_sent, params: { id: payout.id }
      assert_redirected_to workspace_payroll_path(month: @month)
      assert payout.reload.sent?

      other = users(:organization_admin)
      payout.destroy
      payout = unclear_payout(user: other)
      delete :release, params: { id: payout.id }
      assert_redirected_to workspace_payroll_path(month: @month)
      assert_nil PayrollPayout.find_by(id: payout.id)
    end

    test "members cannot resolve payouts" do
      payout = unclear_payout
      sign_in @member
      patch :mark_sent, params: { id: payout.id }
      assert_redirected_to root_path
      delete :release, params: { id: payout.id }
      assert_redirected_to root_path
      assert payout.reload.unclear?
    end

    test "an admin of another organization cannot resolve payouts" do
      payout = unclear_payout
      other_admin = users(:customer_admin)
      other_admin.current_organization.create_tripletex_integration!(employee_token: "y")
      sign_in other_admin
      patch :mark_sent, params: { id: payout.id }
      assert_redirected_to root_path
      delete :release, params: { id: payout.id }
      assert_redirected_to root_path
      assert payout.reload.unclear?
    end
  end
end
