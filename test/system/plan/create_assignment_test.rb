require_relative "plan_system_test_case"

class Plan::CreateAssignmentTest < PlanSystemTestCase
  setup do
    @existing = schedule!(@joe, @crm, MONDAY, MONDAY + 1, 2)
    @crm_row = "#{person_key(@joe)}-#{@crm.id}"
  end

  def open_joe
    sign_in_and_visit
    expand person_key(@joe)
  end

  def project_select = all(".plan-modal select")[0]
  def person_select = all(".plan-modal select")[1]

  test "dragging across empty days opens a prefilled assignment and saves it" do
    open_joe
    draw_assignment @crm_row, from: MONDAY + 7, to: MONDAY + 9

    within_modal do
      assert_text ui("assignment.new_title")
      assert_text @joe.name
      assert_equal @crm.id.to_s, project_select.value
      assert_equal person_key(@joe), person_select.value
      assert_equal [ (MONDAY + 7).iso8601, (MONDAY + 9).iso8601 ], date_fields.map(&:value)
      assert_equal "7.5", hours_per_day_field.value
      assert_equal "22.5", total_hours_field.value
      assert_text ui("across_days", days: 3)
      assert_text ui("percent_of_capacity", percent: 100, hours: "7.5")
      save_modal
    end

    assert_toast "assignment_saved"
    created = @organization.plan_assignments.order(:id).last
    assert_equal [ MONDAY + 7, MONDAY + 9, 450 ], [ created.start_date, created.end_date, created.minutes_per_day ]
    within(row(@crm_row)) { assert_selector ".plan-bar[data-assignment-id='#{created.id}']", text: "7.5h" }
  end

  test "dragging right to left gives the same range" do
    open_joe
    timeline = row(@crm_row).find(".plan-timeline")
    actions.move_to(timeline.native, offset_for(timeline, 10), 0).click_and_hold.move_by(-(2 * day_width).round, 0).release.perform

    within_modal { assert_equal [ (MONDAY + 8).iso8601, (MONDAY + 10).iso8601 ], date_fields.map(&:value) }
  end

  test "a drag preview follows the pointer until release" do
    open_joe
    timeline = row(@crm_row).find(".plan-timeline")
    actions.move_to(timeline.native, offset_for(timeline, 7), 0).click_and_hold.move_by((3 * day_width).round, 0).perform

    ghost = find(".plan-ghost")
    assert_in_delta 4 * day_width, ghost.native.rect.width, 2

    actions.release.perform
    assert_selector ".plan-modal"
    assert_no_selector ".plan-ghost"
  end

  test "assign to project starts from today for a working week" do
    open_joe
    row("#{person_key(@joe)}-add").find("select").select(@billing.name)

    within_modal do
      assert_equal @billing.id.to_s, project_select.value
      assert_equal [ TODAY.iso8601, (TODAY + 4).iso8601 ], date_fields.map(&:value)
      assert_text ui("across_days", days: 3) # Wed, Thu, Fri
      save_modal
    end

    assert_toast "assignment_saved"
    assert_selector ".plan-row[data-row='#{person_key(@joe)}-#{@billing.id}'] .plan-bar"
    # The select snaps back so the next person can be assigned straight away.
    assert_equal "", row("#{person_key(@joe)}-add").find("select").value
  end

  test "time off is booked through the same flow" do
    open_joe
    row("#{person_key(@joe)}-add").find("select").select(ui("time_off"), match: :first)

    within_modal do
      assert_equal "timeoff", project_select.value
      find("textarea").fill_in(with: "Autumn holiday")
      save_modal
    end

    assert_toast "assignment_saved"
    time_off = @organization.plan_assignments.time_off.last
    assert_equal "Autumn holiday", time_off.notes
    assert_includes bar(time_off)[:class], "plan-c-timeoff"
  end

  test "repeat weekly creates one assignment per week" do
    open_joe
    draw_assignment @crm_row, from: MONDAY + 7, to: MONDAY + 7

    within_modal do
      check ui("assignment.repeat")
      find("input[max='52']").fill_in(with: "3")
      save_modal
    end

    assert_toast "assignment_saved"
    starts = @organization.plan_assignments.where(user: @joe, project: @crm).where.not(id: @existing.id).order(:start_date).pluck(:start_date)
    assert_equal [ MONDAY + 7, MONDAY + 14, MONDAY + 21 ], starts
    within(row(@crm_row)) { assert_selector ".plan-bar", count: 4 }
  end

  test "typing a total spreads it over the working days" do
    open_joe
    draw_assignment @crm_row, from: MONDAY + 7, to: MONDAY + 13 # Mon–Sun, five working days

    within_modal do
      assert_text ui("across_days", days: 5)
      total_hours_field.fill_in(with: "10")
      assert_equal "2", hours_per_day_field.value
      hours_per_day_field.fill_in(with: "3")
      assert_equal "15", total_hours_field.value
      assert_text ui("percent_of_capacity", percent: 40, hours: "7.5")
    end
  end

  test "invalid input is explained and nothing is saved" do
    open_joe
    draw_assignment @crm_row, from: MONDAY + 7, to: MONDAY + 9

    within_modal do
      set_date date_fields[1], MONDAY + 6
      save_modal
      assert_selector ".plan-form-error", text: ui("errors.end_before_start")

      set_date date_fields[1], MONDAY + 9
      hours_per_day_field.fill_in(with: "30")
      save_modal
      assert_selector ".plan-form-error", text: ui("errors.hours_invalid")
    end

    assert_equal 1, @organization.plan_assignments.count
  end

  test "server-side validation errors are shown in the dialog" do
    open_joe
    draw_assignment @crm_row, from: MONDAY + 7, to: MONDAY + 9

    within_modal do
      find("textarea").set("x" * 2001)
      save_modal
      assert_selector ".plan-form-error", text: /Notes is too long/
      assert_selector "button[type=submit]:not([disabled])"
    end
    assert_equal 1, @organization.plan_assignments.count
  end

  test "the dialog closes with cancel, the close button, Escape or a click outside" do
    open_joe

    draw_assignment @crm_row, from: MONDAY + 7, to: MONDAY + 8
    within_modal { click_on ui("cancel") }
    assert_no_selector ".plan-modal"

    draw_assignment @crm_row, from: MONDAY + 7, to: MONDAY + 8
    find(".plan-modal [aria-label='Close']").click
    assert_no_selector ".plan-modal"

    draw_assignment @crm_row, from: MONDAY + 7, to: MONDAY + 8
    find(".plan-modal textarea").send_keys(:escape)
    assert_no_selector ".plan-modal"

    draw_assignment @crm_row, from: MONDAY + 7, to: MONDAY + 8
    backdrop = find(".plan-modal-backdrop")
    backdrop.click(x: -(backdrop.native.rect.width / 2 - 10).round, y: -(backdrop.native.rect.height / 2 - 10).round)
    assert_no_selector ".plan-modal"

    assert_equal 1, @organization.plan_assignments.count
  end

  test "people can be drawn onto a project from the projects view" do
    sign_in_and_visit "projects"
    expand project_key(@crm)
    draw_assignment "#{project_key(@crm)}-#{person_key(@joe)}", from: MONDAY + 14, to: MONDAY + 16

    within_modal do
      assert_equal @crm.id.to_s, project_select.value
      assert_equal person_key(@joe), person_select.value
      save_modal
    end
    assert_toast "assignment_saved"
  end

  test "a placeholder is assigned to a project from the projects view" do
    designer = placeholder!("Designer")
    sign_in_and_visit "projects"
    expand project_key(@billing)
    row("#{project_key(@billing)}-add").find("select").select(designer.name)

    within_modal do
      assert_equal placeholder_key(designer), person_select.value
      assert_equal "7.5", hours_per_day_field.value # placeholders get the organization's default day
      save_modal
    end

    assert_toast "assignment_saved"
    assert_selector ".plan-row[data-row='#{project_key(@billing)}-#{placeholder_key(designer)}'] .plan-bar"
    assert_equal designer, @organization.plan_assignments.last.placeholder
  end
end
