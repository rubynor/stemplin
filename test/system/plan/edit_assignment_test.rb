require_relative "plan_system_test_case"

class Plan::EditAssignmentTest < PlanSystemTestCase
  setup do
    @assignment = schedule!(@joe, @crm, MONDAY + 7, MONDAY + 11, 4, notes: "Sprint 12") # Mon–Fri next week
    sign_in_and_visit
    expand person_key(@joe)
  end

  def dates(record) = record.reload.then { |r| [ r.start_date, r.end_date ] }

  test "dragging a bar moves the assignment" do
    drag_bar bar(@assignment), 2

    assert_eventually { dates(@assignment) == [ MONDAY + 9, MONDAY + 13 ] }
    assert_in_delta 9 * day_width, bar(@assignment).native.rect.x - row("#{person_key(@joe)}-#{@crm.id}").find(".plan-timeline").native.rect.x, 3
  end

  test "dragging back and forth to the same day saves nothing" do
    before = @assignment.updated_at
    actions.move_to(bar(@assignment).native).click_and_hold.move_by((2 * day_width).round, 0).move_by(-(2 * day_width).round, 0).release.perform

    assert_no_selector ".plan-modal"
    assert_equal before, @assignment.reload.updated_at
  end

  test "dragging the right edge changes the end date" do
    drag_handle @assignment, "end", 2

    assert_eventually { dates(@assignment) == [ MONDAY + 7, MONDAY + 13 ] }
  end

  test "dragging the left edge changes the start date" do
    drag_handle @assignment, "start", -3

    assert_eventually { dates(@assignment) == [ MONDAY + 4, MONDAY + 11 ] }
  end

  test "an edge cannot be dragged past the other end" do
    drag_handle @assignment, "end", -9

    assert_eventually { dates(@assignment) == [ MONDAY + 7, MONDAY + 7 ] }
  end

  test "alt-dragging copies the assignment" do
    drag_bar bar(@assignment), 7, alt: true

    assert_toast "assignment_copied"
    copy = @organization.plan_assignments.where.not(id: @assignment.id).sole
    assert_equal [ MONDAY + 14, MONDAY + 18, 240, "Sprint 12" ], [ copy.start_date, copy.end_date, copy.minutes_per_day, copy.notes ]
    assert_equal [ MONDAY + 7, MONDAY + 11 ], dates(@assignment)
    assert_selector ".plan-bar[data-assignment-id='#{copy.id}']"
  end

  test "clicking a bar opens it for editing with its current values" do
    click_bar @assignment

    within_modal do
      assert_text ui("assignment.edit_title")
      assert_equal [ (MONDAY + 7).iso8601, (MONDAY + 11).iso8601 ], date_fields.map(&:value)
      assert_equal "4", hours_per_day_field.value
      assert_equal "20", total_hours_field.value
      assert_equal "Sprint 12", find("textarea").value
      assert_no_text ui("assignment.repeat")
    end
  end

  test "hours, dates and notes are updated from the dialog" do
    click_bar @assignment

    within_modal do
      hours_per_day_field.fill_in(with: "6")
      set_date date_fields[1], MONDAY + 9
      find("textarea").fill_in(with: "Shorter sprint")
      save_modal
    end

    assert_toast "assignment_saved"
    @assignment.reload
    assert_equal [ 360, MONDAY + 9, "Shorter sprint" ], [ @assignment.minutes_per_day, @assignment.end_date, @assignment.notes ]
    assert_selector ".plan-bar[data-assignment-id='#{@assignment.id}']", text: "6h"
  end

  test "moving an assignment to another project and person" do
    click_bar @assignment

    within_modal do
      all("select")[0].select(@billing.name)
      all("select")[1].select(@member.name)
      save_modal
    end

    assert_toast "assignment_saved"
    assert_eventually { @assignment.reload.user == @member }
    assert_equal @billing, @assignment.project
    assert_no_selector ".plan-row[data-row='#{person_key(@joe)}-#{@crm.id}']"

    expand person_key(@member)
    assert_selector ".plan-row[data-row='#{person_key(@member)}-#{@billing.id}'] .plan-bar[data-assignment-id='#{@assignment.id}']"
  end

  test "an assignment is split in two" do
    click_bar @assignment

    within_modal do
      assert_equal (MONDAY + 10).iso8601, find(".plan-split input[type=date]").value
      find(".plan-split input[type=date]").fill_in(with: MONDAY + 9)
      click_on ui("assignment.split")
    end

    assert_toast "assignment_split"
    first, second = @organization.plan_assignments.order(:start_date).to_a
    assert_equal [ MONDAY + 7, MONDAY + 8 ], [ first.start_date, first.end_date ]
    assert_equal [ MONDAY + 9, MONDAY + 11 ], [ second.start_date, second.end_date ]
    within(row("#{person_key(@joe)}-#{@crm.id}")) { assert_selector ".plan-bar", count: 2 }
  end

  test "one-day assignments cannot be split" do
    one_day = schedule!(@joe, @crm, MONDAY + 14, MONDAY + 14, 2)
    visit_plan
    expand person_key(@joe)
    click_bar one_day

    within_modal { assert_no_selector ".plan-split" }
  end

  test "deleting asks for confirmation first" do
    click_bar @assignment

    within_modal do
      click_on ui("delete")
      assert_equal 1, Plan::Assignment.count
      click_on ui("confirm_delete")
    end

    assert_toast "assignment_deleted"
    assert_eventually { !Plan::Assignment.exists?(@assignment.id) }
    assert_no_selector ".plan-bar[data-assignment-id='#{@assignment.id}']"
  end

  test "saving an assignment someone else deleted explains the problem" do
    click_bar @assignment
    @assignment.destroy!

    within_modal do
      hours_per_day_field.fill_in(with: "5")
      save_modal
      assert_selector ".plan-form-error", text: I18n.t("plan.errors.not_found")
    end
  end

  test "a failed drag puts the bar back where the server has it" do
    moved_elsewhere = MONDAY + 14
    @assignment.update_columns(start_date: moved_elsewhere, end_date: moved_elsewhere + 4)
    @assignment.destroy!
    ghost = schedule!(@joe, @crm, MONDAY + 7, MONDAY + 11, 4)
    visit_plan
    expand person_key(@joe)
    ghost_id = ghost.id
    ghost.destroy!

    drag_bar find(".plan-bar[data-assignment-id='#{ghost_id}']"), 1

    assert_selector ".plan-toast.is-error", text: ui("toast.save_failed")
    assert_no_selector ".plan-bar[data-assignment-id='#{ghost_id}']"
  end
end
