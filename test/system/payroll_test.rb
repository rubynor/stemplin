require "application_system_test_case"

class PayrollSystemTest < ApplicationSystemTestCase
  teardown { FakeTripletexApi.reset }

  test "admin locks for a member and pays out the month" do
    organization = organizations(:organization_one)
    member = users(:organization_user)
    period = Date.current.last_month.beginning_of_month
    organization.create_tripletex_integration!(employee_token: "x", hourly_salary_type_id: 31)
    member.access_info(organization).update!(tripletex_employee_id: 7)
    member.time_regs.create!(assigned_task: assigned_task(:task_1), minutes: 125, date_worked: period + 3)
    fake = FakeTripletexApi.install(FakeTripletexApi.new(pay_details: { 7 => { "remunerationType" => "HOURLY_WAGE", "hourlyWage" => BigDecimal("250") } }))
    row = "#payroll_row_#{member.id}"

    sign_in_as users(:organization_admin)
    visit workspace_payroll_path

    within(row) { click_on I18n.t("tripletex.payroll.actions.lock") }
    within("#turbo-confirm-dialog") { click_on "Accept" }
    assert_text I18n.t("tripletex.locks.locked_notice", month: I18n.l(period, format: "%B %Y"))

    within(row) { click_on I18n.t("tripletex.payroll.actions.payout") }
    within("#turbo-confirm-dialog") { click_on "Accept" }

    within(row) do
      assert_text I18n.t("tripletex.payroll.statuses.sent")
      assert_text I18n.l(Date.current, format: "%d.%m.%Y")
      assert_no_button I18n.t("tripletex.payroll.actions.payout")
    end
    assert_equal 1, fake.salary_runs.size
  end
end
