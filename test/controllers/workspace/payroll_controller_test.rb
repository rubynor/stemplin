require "test_helper"

module Workspace
  class PayrollControllerTest < ActionController::TestCase
    setup do
      @organization = organizations(:organization_one)
      @admin = users(:organization_admin)
      @member = users(:organization_user)
      @integration = @organization.create_tripletex_integration!(employee_token: "x", hourly_salary_type_id: 31)
      @period = Date.current.last_month.beginning_of_month
      @member.time_regs.create!(assigned_task: assigned_task(:task_1), minutes: 125, date_worked: @period + 3)
      FakeTripletexApi.install(FakeTripletexApi.new(pay_details: { 7 => { "remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal("250") } }))
    end

    teardown { FakeTripletexApi.reset }

    def link_member
      @member.access_info(@organization).update!(tripletex_employee_id: 7)
    end

    def lock_member(period = @period)
      TimeLock.create!(organization: @organization, user: @member, locked_by: @admin, period: period)
    end

    def member_row
      "#payroll_row_#{@member.id}"
    end

    test "admin sees a row with hours per member, defaulting to last month" do
      sign_in @admin
      get :show

      assert_response :success
      assert_select "[data-role=month]", text: I18n.l(@period, format: "%B %Y")
      assert_select member_row, text: /2.08/
      assert_select "#payroll_row_#{@admin.id}"
    end

    test "the sidebar links to payroll only when connected" do
      sign_in @admin
      get :show
      assert_select "nav a[href='#{workspace_payroll_path}']"

      @integration.destroy
      @organization.reload
      @controller = Workspace::TeamMembersController.new
      get :index
      assert_select "nav a[href='#{workspace_payroll_path}']", count: 0
    end

    test "month param selects the month" do
      sign_in @admin
      get :show, params: { month: "2026-10" }
      assert_select "[data-role=month]", text: I18n.l(Date.new(2026, 10, 1), format: "%B %Y")
    end

    test "an unparseable month falls back to last month" do
      sign_in @admin
      get :show, params: { month: "nonsense" }
      assert_select "[data-role=month]", text: I18n.l(@period, format: "%B %Y")
    end

    test "members and spectators are redirected" do
      sign_in users(:organization_user)
      get :show
      assert_redirected_to root_path
      sign_out users(:organization_user)

      sign_in users(:organization_spectator)
      get :show
      assert_redirected_to reports_path
    end

    test "an admin without an integration is redirected to the integrations page" do
      @integration.destroy
      sign_in @admin
      get :show
      assert_redirected_to workspace_integrations_path
    end

    test "a ready row has a payout button and unlock" do
      link_member
      lock_member
      sign_in @admin
      get :show

      assert_select "#{member_row} form[action^='#{workspace_payroll_payouts_path}']", count: 1
      assert_select "#{member_row} form[action^='#{workspace_payroll_payouts_path}'][data-turbo-confirm*='520']"
      assert_select "#{member_row} form[action^='/time_locks/']"
      assert_includes response.body, "expected_rate=250.0"
    end

    test "a not locked row has the lock button and no payout button" do
      link_member
      sign_in @admin
      get :show

      assert_select "#{member_row} form[action^='/time_locks']", count: 1
      assert_select "#{member_row} form[action^='#{workspace_payroll_payouts_path}']", count: 0
    end

    test "the current month cannot be locked and shows preliminary hours" do
      link_member
      @member.time_regs.create!(assigned_task: assigned_task(:task_1), minutes: 60, date_worked: Date.current)
      sign_in @admin
      get :show, params: { month: Date.current.strftime("%Y-%m") }

      assert_select "#{member_row} form[action^='/time_locks']", count: 0
      assert_select member_row, text: /#{I18n.t("tripletex.payroll.preliminary")}/
    end

    test "an unlinked row has the link action" do
      sign_in @admin
      get :show
      assert_select "#{member_row} form[action='#{edit_modal_workspace_team_member_path(@member)}']"
    end

    test "a locked row that is not linked shows unlock" do
      lock_member
      sign_in @admin
      get :show

      assert_select member_row, text: /#{I18n.t("tripletex.payroll.statuses.not_linked")}/
      assert_select "#{member_row} form[action^='/time_locks/']", count: 1
    end

    test "a locked row with no hours shows unlock" do
      link_member
      lock = lock_member
      @member.time_regs.where(date_worked: @period..@period.end_of_month).update_all(discarded_at: Time.current)
      sign_in @admin
      get :show

      assert_select member_row, text: /#{I18n.t("tripletex.payroll.statuses.no_hours")}/
      assert_select "#{member_row} form[action='#{time_lock_path(lock)}']", count: 1
    end

    test "locked by another shows who locked" do
      link_member
      lock_member
      sign_in @admin
      get :show
      assert_select member_row, text: /#{Regexp.escape(I18n.t("tripletex.payroll.locked_by", name: @admin.name.presence || @admin.email))}/
    end

    test "with no salary type the page asks to choose one and has no payout buttons" do
      @integration.update!(hourly_salary_type_id: nil)
      link_member
      lock_member
      sign_in @admin
      get :show

      assert_includes response.body, I18n.t("tripletex.payroll.choose_salary_type")
      assert_select "form[action^='#{workspace_payroll_payouts_path}']", count: 0
    end

    test "when Tripletex fails hours show, the error shows once and nothing can be paid" do
      link_member
      lock_member
      FakeTripletexApi.install(FakeTripletexApi.new(error: "Tripletex er nede"))
      sign_in @admin
      get :show

      assert_select member_row, text: /2.08/
      assert_equal 1, response.body.scan("Tripletex er nede").size
      assert_select "form[action^='#{workspace_payroll_payouts_path}']", count: 0
      assert_select member_row, text: /#{I18n.t("tripletex.payroll.statuses.unsupported")}/, count: 0
      assert_select "#{member_row} form[action^='/time_locks/']", count: 1
    end

    test "a sent row shows the date and no actions" do
      link_member
      lock_member
      PayrollPayout.create!(organization: @organization, user: @member, period: @period, sent_by: @admin, status: :sent, sent_at: Time.current,
                            minutes: 125, hours: 2.08, hourly_wage: 250, amount: 520, tripletex_employee_id: 7)
      sign_in @admin
      get :show

      assert_select member_row, text: /#{Regexp.escape(I18n.l(Date.current, format: "%d.%m.%Y"))}/
      assert_select "#{member_row} form", count: 0
    end

    test "an unclear row shows the stored message and the resolve buttons" do
      link_member
      lock_member
      PayrollPayout.create!(organization: @organization, user: @member, period: @period, sent_by: @admin, status: :unclear, error_message: "Lost contact",
                            minutes: 125, hours: 2.08, hourly_wage: 250, amount: 520, tripletex_employee_id: 7)
      sign_in @admin
      get :show

      assert_select member_row, text: /Lost contact/
      assert_select "#{member_row} form", count: 2
      assert_select "#{member_row} form[action*='mark_sent']"
    end
  end
end
