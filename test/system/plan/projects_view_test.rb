require_relative "plan_system_test_case"

class Plan::ProjectsViewTest < PlanSystemTestCase
  setup do
    @joe_crm = schedule!(@joe, @crm, MONDAY, MONDAY + 4, 4)
    @member_crm = schedule!(@member, @crm, MONDAY + 7, MONDAY + 9, 6)
    @joe_off = schedule!(@joe, nil, MONDAY + 14, MONDAY + 15, 7.5)
    @launch = @organization.plan_milestones.create!(project: @crm, name: "Launch", date: MONDAY + 10)
  end

  def open_projects
    sign_in_and_visit "projects"
  end

  def milestone(record) = find(".plan-milestone[data-milestone-id='#{record.id}']")

  test "every project of the organization gets a row, grouped by client, with time off first" do
    open_projects

    keys = all(".plan-rows > .plan-row.plan-parent").map { |r| r["data-row"] }
    assert_equal "p-timeoff", keys.first
    assert_includes keys, project_key(@crm)
    assert_includes keys, project_key(@billing)
    assert_not_includes keys, project_key(projects(:org_two_project))

    within(row(project_key(@crm))) do
      assert_text clients(:e_corp).name
      assert_selector ".plan-stripe"
    end
  end

  test "a collapsed project shows everyone's bars with initials" do
    open_projects

    within(row(project_key(@crm))) do
      assert_selector ".plan-bar[data-assignment-id='#{@joe_crm.id}']", text: "JD 4h"
      assert_selector ".plan-bar[data-assignment-id='#{@member_crm.id}']", text: "OU 6h"
    end
  end

  test "expanding a project lists the people on it" do
    open_projects
    expand project_key(@crm)

    assert_selector ".plan-row[data-row='#{project_key(@crm)}-#{person_key(@joe)}']", text: @joe.name
    assert_selector ".plan-row[data-row='#{project_key(@crm)}-#{person_key(@member)}']", text: @member.name
    assert_selector ".plan-row[data-row='#{project_key(@crm)}-add'] select"
    within(row("#{project_key(@crm)}-#{person_key(@joe)}")) { assert_selector ".plan-bar", text: "4h" }
  end

  test "the time off row gathers everyone's time off" do
    open_projects
    expand "p-timeoff"

    assert_selector ".plan-row[data-row='p-timeoff-#{person_key(@joe)}'] .plan-bar[data-assignment-id='#{@joe_off.id}']"
  end

  test "hiding projects without assignments" do
    open_projects
    check ui("only_scheduled")

    assert_selector ".plan-row[data-row='#{project_key(@crm)}']"
    assert_no_selector ".plan-row[data-row='#{project_key(@billing)}']"

    uncheck ui("only_scheduled")
    assert_selector ".plan-row[data-row='#{project_key(@billing)}']"
  end

  test "search matches project, client and the people on a project" do
    open_projects

    find(".plan-search-input").fill_in(with: "billing sys")
    assert_selector ".plan-row[data-row='#{project_key(@billing)}']"
    assert_no_selector ".plan-row[data-row='#{project_key(@crm)}']"

    find(".plan-search-input").fill_in(with: @member.name)
    assert_selector ".plan-row[data-row='#{project_key(@crm)}']"
    assert_no_selector ".plan-row[data-row='#{project_key(@billing)}']"
  end

  test "milestones sit on their date and show their name" do
    open_projects

    assert_text "Launch"
    timeline = row(project_key(@crm)).find(".plan-timeline")
    assert_in_delta 10.5 * day_width, milestone(@launch).native.rect.x - timeline.native.rect.x + 5, 3
    assert_includes milestone(@launch)[:title], "Launch"
  end

  test "clicking the project row adds a milestone on that day" do
    open_projects
    timeline = row(project_key(@billing)).find(".plan-timeline")
    timeline.click(x: offset_for(timeline, 3), y: 0)

    within_modal do
      assert_text ui("milestone.new_title")
      assert_text @billing.name
      assert_equal (MONDAY + 3).iso8601, find("input[type=date]").value
      find("input:not([type=date])").fill_in(with: "Kick-off")
      save_modal
    end

    assert_toast "milestone_saved"
    created = @billing.plan_milestones.sole
    assert_equal [ "Kick-off", MONDAY + 3 ], [ created.name, created.date ]
    within(row(project_key(@billing))) { assert_text "Kick-off" }
  end

  test "a milestone needs a name" do
    open_projects
    timeline = row(project_key(@billing)).find(".plan-timeline")
    timeline.click(x: offset_for(timeline, 3), y: 0)

    within_modal do
      save_modal
      assert_selector ".plan-form-error", text: ui("errors.name_required")
    end
    assert_equal 0, @billing.plan_milestones.count
  end

  test "milestones are renamed, moved and deleted" do
    open_projects
    milestone(@launch).click

    within_modal do
      assert_text ui("milestone.edit_title")
      find("input:not([type=date])").fill_in(with: "Go live")
      find("input[type=date]").fill_in(with: MONDAY + 12)
      save_modal
    end
    assert_toast "milestone_saved"
    assert_eventually { @launch.reload.name == "Go live" }
    assert_equal MONDAY + 12, @launch.date

    milestone(@launch).click
    within_modal { click_on ui("delete") }
    assert_toast "milestone_deleted"
    assert_no_selector ".plan-milestone[data-milestone-id='#{@launch.id}']"
    assert_not Plan::Milestone.exists?(@launch.id)
  end

  test "the colour label is changed from the project dialog" do
    open_projects
    row(project_key(@crm)).hover
    row(project_key(@crm)).find(".plan-row-action").click

    within_modal do
      find(".plan-swatch.plan-c-magenta").click
      assert_selector ".plan-swatch.plan-c-magenta.is-selected"
    end
    assert_eventually { @crm.reload.plan_color == "magenta" }
    assert_includes row(project_key(@crm)).find(".plan-stripe")[:class], "plan-c-magenta"

    visit_plan "projects"
    assert_includes bar(@joe_crm)[:class], "plan-c-magenta"
  end

  test "shifting the timeline moves later assignments and milestones" do
    open_projects
    row(project_key(@crm)).hover
    row(project_key(@crm)).find(".plan-row-action").click

    within_modal do
      shift = all(".plan-shift input[type=date]")
      shift[0].fill_in(with: MONDAY + 7)
      shift[1].fill_in(with: MONDAY + 14)
      click_on ui("project.shift")
    end

    assert_toast "timeline_shifted"
    assert_eventually { @member_crm.reload.start_date == MONDAY + 14 }
    assert_equal MONDAY + 17, @launch.reload.date
    assert_equal MONDAY, @joe_crm.reload.start_date, "work before the shift date stays put"
    assert_equal MONDAY + 14, @joe_off.reload.start_date, "time off is not part of the project"
  end

  test "the project dialog links to adding a milestone" do
    open_projects
    row(project_key(@billing)).hover
    row(project_key(@billing)).find(".plan-row-action").click
    within_modal { click_on "+ #{ui('milestone.new_title')}" }

    within_modal do
      assert_text ui("milestone.new_title")
      assert_equal TODAY.iso8601, find("input[type=date]").value
    end
  end

  test "new projects are created in the workspace" do
    open_projects
    click_on "+ #{ui('new_project')}"

    assert_current_path workspace_projects_path
  end
end
