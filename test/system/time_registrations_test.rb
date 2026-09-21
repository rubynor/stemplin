require "application_system_test_case"

class TimeRegistrationsTest < ApplicationSystemTestCase
  test "admin logs time through the modal" do
    # An organization admin is used because members only see the projects they
    # have explicit access to, and the fixture member has none.
    admin = users(:organization_admin)
    sign_in_as admin

    assert_difference -> { admin.time_regs.count }, 1 do
      first("button", text: I18n.t("common.log_time")).click

      # The dialog component moves the form out of its turbo frame, so the
      # fields are addressed directly rather than scoped to the frame.
      select projects(:project_1).name, from: "time_reg_project_id"
      # The task list is filled in by the time-tasks Stimulus controller in
      # response to the project selection; Capybara waits for it to appear.
      select tasks(:coding).name, from: "time_reg_assigned_task_id"
      fill_in "time_reg_notes", with: "Pair programming on the invoice screen"
      fill_in "time_reg_minutes_string", with: "1:30"
      find("form#new_time_reg button[type='submit']").click

      assert_text "Pair programming on the invoice screen"
    end

    time_reg = admin.time_regs.order(:created_at).last
    # minutes is a hidden field kept in sync by the custom-input Stimulus
    # controller. If that breaks, entries save silently as zero minutes.
    assert_equal 90, time_reg.minutes
    assert_equal tasks(:coding), time_reg.task
  end

  test "user starts and stops the timer on an entry" do
    sign_in_as users(:joe)
    time_reg = time_regs(:time_reg_1)
    row = "##{ActionView::RecordIdentifier.dom_id(time_reg)}"

    within(row) { click_on I18n.t("common.start") }
    within(row) { assert_text I18n.t("common.stop") }
    assert time_reg.reload.active?

    within(row) { click_on I18n.t("common.stop") }
    within(row) { assert_text I18n.t("common.start") }
    assert_not time_reg.reload.active?
  end

  test "user edits an existing entry through the modal" do
    sign_in_as users(:joe)
    time_reg = time_regs(:time_reg_1)

    within "##{ActionView::RecordIdentifier.dom_id(time_reg)}" do
      # The row actions are icon-only buttons labelled for screen readers.
      find("button[aria-label='#{I18n.t("common.edit")}']").click
    end

    fill_in "time_reg_notes", with: "Rewrote the weekly summary"
    find("form#time_reg_#{time_reg.id} button[type='submit']").click

    assert_text "Rewrote the weekly summary"
    assert_equal "Rewrote the weekly summary", time_reg.reload.notes
  end
end
