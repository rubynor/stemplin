require_relative "plan_system_test_case"

class Plan::TeamViewTest < PlanSystemTestCase
  setup do
    # Joe (37.5h/week, Mon–Fri): 4h/day on CRM all week, 3.5h Billing on
    # Wednesday and a day off on Thursday.
    @crm_week = schedule!(@joe, @crm, MONDAY, MONDAY + 4, 4)
    @billing_day = schedule!(@joe, @billing, MONDAY + 2, MONDAY + 2, 3.5)
    @day_off = schedule!(@joe, nil, MONDAY + 3, MONDAY + 3, 7.5, notes: "Dentist")
    @designer = placeholder!("Designer", roles: "UX, Senior")
    schedule!(@designer, @crm, MONDAY + 7, MONDAY + 11, 6)
  end

  test "placeholders come first, then people with their weekly capacity" do
    sign_in_and_visit

    keys = all(".plan-rows > .plan-row.plan-parent").map { |r| r["data-row"] }
    assert_equal placeholder_key(@designer), keys.first
    assert_includes keys, person_key(@joe)

    within(row(placeholder_key(@designer))) { assert_text "UX, Senior" }
    within(row(person_key(@joe))) { assert_text ui("capacity_per_week", hours: "37.5") }
  end

  test "daily availability shows free hours and flags full and overbooked days" do
    sign_in_and_visit
    joe = person_key(@joe)

    assert_equal "3.5", heat(joe, MONDAY).text
    assert_includes heat(joe, MONDAY)[:class], "is-partial"
    assert_equal "0", heat(joe, MONDAY + 2).text
    assert_includes heat(joe, MONDAY + 2)[:class], "is-full"
    assert_equal "-4", heat(joe, MONDAY + 3).text
    assert_includes heat(joe, MONDAY + 3)[:class], "is-over"
    assert_equal "7.5", heat(joe, MONDAY + 7).text
    assert_includes heat(joe, MONDAY + 7)[:class], "is-free"
  end

  test "placeholders show the hours booked on them" do
    sign_in_and_visit

    assert_equal "6", heat(placeholder_key(@designer), MONDAY + 7).text
    assert_no_selector ".plan-row[data-row='#{placeholder_key(@designer)}'] .plan-heat[data-date='#{MONDAY.iso8601}']"
  end

  test "weekly capacity shows booked hours out of capacity per week" do
    sign_in_and_visit
    find(".plan-head select").select(ui("heat.weekly"))

    assert_equal "31 / 37.5", heat(person_key(@joe), MONDAY).text
    assert_equal "0 / 37.5", heat(person_key(@joe), MONDAY + 7).text
  end

  test "in week zoom availability is summed per week" do
    sign_in_and_visit "team"
    click_on ui("zoom.week")

    assert_equal "6.5", heat(person_key(@joe), MONDAY).text
    assert_equal "37.5", heat(person_key(@joe), MONDAY + 7).text
  end

  test "weekends and a person's days off get no availability cell" do
    access_infos(:access_info_1).update!(plan_work_days: 0b0001111) # Mon–Thu
    sign_in_and_visit

    joe = person_key(@joe)
    assert_equal "5.38", heat(joe, MONDAY).text # 37.5h over four days = 9.375h/day
    assert_no_selector ".plan-row[data-row='#{joe}'] .plan-heat[data-date='#{(MONDAY + 4).iso8601}']"
    assert_no_selector ".plan-row[data-row='#{joe}'] .plan-heat[data-date='#{(MONDAY + 5).iso8601}']"
  end

  test "expanding a person lists a row per project and one for time off" do
    sign_in_and_visit
    joe = person_key(@joe)
    expand joe

    assert_selector ".plan-row[data-row='#{joe}-timeoff']", text: ui("time_off")
    assert_selector ".plan-row[data-row='#{joe}-#{@crm.id}']", text: @crm.name
    assert_selector ".plan-row[data-row='#{joe}-#{@billing.id}']", text: @billing.name
    assert_selector ".plan-row[data-row='#{joe}-add'] select"

    within(row("#{joe}-#{@crm.id}")) { assert_selector ".plan-bar", text: "4h" }
    assert_includes bar(@day_off)[:class], "has-notes"
    assert_includes bar(@day_off)[:title], "Dentist"

    row(joe).find(".plan-expand").click
    assert_no_selector ".plan-row[data-row='#{joe}-#{@crm.id}']"
  end

  test "expand all and collapse all" do
    sign_in_and_visit

    find(".plan-icon-button[title='#{ui('expand_all')}']").click
    assert_selector ".plan-row[data-row='#{person_key(@joe)}-#{@crm.id}']"
    assert_selector ".plan-row[data-row='#{placeholder_key(@designer)}-#{@crm.id}']"

    find(".plan-icon-button[title='#{ui('expand_all')}']").click
    assert_no_selector ".plan-row.plan-child"
  end

  test "overlapping assignments in one row are stacked in lanes" do
    overlap = schedule!(@joe, @crm, MONDAY + 1, MONDAY + 2, 2)
    sign_in_and_visit
    expand person_key(@joe)

    assert_not_equal bar(@crm_week).native.rect.y, bar(overlap).native.rect.y
  end

  test "search narrows the team by name or by the projects people work on" do
    sign_in_and_visit

    find(".plan-search-input").fill_in(with: "designer")
    assert_selector ".plan-row[data-row='#{placeholder_key(@designer)}']"
    assert_no_selector ".plan-row[data-row='#{person_key(@joe)}']"

    find(".plan-search-input").fill_in(with: @billing.name.downcase)
    assert_selector ".plan-row[data-row='#{person_key(@joe)}']"
    assert_no_selector ".plan-row[data-row='#{placeholder_key(@designer)}']"

    find(".plan-search-input").fill_in(with: "")
    assert_selector ".plan-row[data-row='#{placeholder_key(@designer)}']"
    assert_selector ".plan-row[data-row='#{person_key(users(:organization_user))}']"
  end
end
