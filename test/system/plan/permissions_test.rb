require_relative "plan_system_test_case"

class Plan::PermissionsTest < PlanSystemTestCase
  setup do
    @joe_crm = schedule!(@joe, @crm, MONDAY, MONDAY + 4, 4)
    @joe_billing = schedule!(@joe, @billing, MONDAY + 7, MONDAY + 9, 3) # member has no access to Billing
    @member_off = schedule!(@member, nil, MONDAY + 2, MONDAY + 2, 7.5)
    @designer = placeholder!("Designer")
    @designer_billing = schedule!(@designer, @billing, MONDAY, MONDAY + 4, 6)
    @milestone = @organization.plan_milestones.create!(project: @crm, name: "Launch", date: MONDAY + 3)
  end

  test "every role finds the Plan in the navigation" do
    [ @admin, @member, users(:organization_spectator) ].each do |user|
      sign_in_as user
      within("header") { assert_link I18n.t("common.plan") }
      Capybara.reset_sessions!
    end
  end

  test "members see their own schedule and the projects they work on, nothing else" do
    sign_in_and_visit "team", as: @member

    assert_selector ".plan-row[data-row='#{person_key(@member)}']"
    assert_selector ".plan-row[data-row='#{person_key(@joe)}']"
    assert_no_selector ".plan-row[data-row='#{person_key(users(:ron))}']"
    assert_no_selector ".plan-row[data-row='#{placeholder_key(@designer)}']"

    expand person_key(@joe)
    assert_selector ".plan-bar[data-assignment-id='#{@joe_crm.id}']"
    assert_no_selector ".plan-bar[data-assignment-id='#{@joe_billing.id}']"

    expand person_key(@member)
    assert_selector ".plan-bar[data-assignment-id='#{@member_off.id}']"

    find(".plan-tabs button", text: ui("tabs.projects")).click
    assert_selector ".plan-row[data-row='#{project_key(@crm)}']"
    assert_no_selector ".plan-row[data-row='#{project_key(@billing)}']"
  end

  test "members get no editing controls" do
    sign_in_and_visit "team", as: @member
    expand person_key(@joe)

    assert_no_button "+ #{ui('add_placeholder')}"
    assert_no_selector ".plan-row.plan-add"
    assert_no_selector ".plan-row-action"
    assert_no_selector ".plan-timeline.is-editable"
    assert_no_selector ".plan-handle", visible: :all

    find(".plan-tabs button", text: ui("tabs.projects")).click
    assert_no_link "+ #{ui('new_project')}"
    assert_no_selector ".plan-timeline.is-milestone-target"
  end

  test "dragging does nothing for members" do
    sign_in_and_visit "team", as: @member
    expand person_key(@joe)

    actions.move_to(bar(@joe_crm).native).click_and_hold.move_by((3 * day_width).round, 0).release.perform
    timeline = row("#{person_key(@joe)}-#{@crm.id}").find(".plan-timeline")
    actions.move_to(timeline.native, offset_for(timeline, 14), 0).click_and_hold.move_by((2 * day_width).round, 0).release.perform

    assert_equal [ MONDAY, MONDAY + 4 ], [ @joe_crm.reload.start_date, @joe_crm.end_date ]
    assert_equal 4, Plan::Assignment.count
  end

  test "members can open an assignment to read it" do
    sign_in_and_visit "team", as: @member
    expand person_key(@joe)
    bar(@joe_crm).click

    within_modal do
      assert_text ui("assignment.view_title")
      assert all("select, input, textarea").all?(&:disabled?)
      assert_no_button ui("assignment.save")
      assert_no_button ui("delete")
      find(".plan-modal-foot button", text: ui("close")).click
    end
    assert_no_selector ".plan-modal"
  end

  test "clicking a milestone does nothing for members" do
    sign_in_and_visit "projects", as: @member
    find(".plan-milestone[data-milestone-id='#{@milestone.id}']").click

    assert_no_selector ".plan-modal"
  end

  test "spectators see the plan read-only" do
    users(:organization_spectator).access_info.project_accesses.find_or_create_by!(project: @crm)
    sign_in_and_visit "projects", as: users(:organization_spectator)

    within(row(project_key(@crm))) { assert_selector ".plan-bar[data-assignment-id='#{@joe_crm.id}']" }
    assert_no_selector ".plan-row[data-row='#{project_key(@billing)}']"
    assert_no_selector ".plan-row-action"
  end

  test "a member's export only contains what they may see" do
    sign_in_and_visit "export", as: @member
    find("#plan-export-timeframe").select(ui("export.two_weeks"))
    assert_selector "a[href*='start=2026-09-21&end=2026-10-04']", text: ui("export.download")

    csv = evaluate_async_script("fetch(arguments[0]).then(r => r.text()).then(arguments[1])", find_link(ui("export.download"))[:href])
    assert_includes csv, @crm.name
    assert_not_includes csv, @billing.name
    assert_not_includes csv, "Designer"
  end

  test "an admin switched to another organization sees none of this one's plan" do
    access_infos(:access_info_org1_admin).update!(active: false)
    access_infos(:access_info_org2_admin).update!(active: true)
    sign_in_and_visit "team"

    assert_no_selector ".plan-row[data-row='#{person_key(@joe)}']"
    assert_no_selector ".plan-row[data-row='#{placeholder_key(@designer)}']"
    find(".plan-tabs button", text: ui("tabs.projects")).click
    assert_selector ".plan-row[data-row='#{project_key(projects(:org_two_project))}']"
    assert_no_selector ".plan-row[data-row='#{project_key(@crm)}']"
    assert_no_selector ".plan-bar"
  end
end
