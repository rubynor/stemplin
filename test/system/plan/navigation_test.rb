require_relative "plan_system_test_case"

class Plan::NavigationTest < PlanSystemTestCase
  test "the Plan link in the navigation opens the projects schedule" do
    sign_in_as @admin
    within("header") { click_on I18n.t("common.plan") }

    assert_selector ".plan-tabs [aria-selected='true']", text: ui("tabs.projects")
    assert_selector ".plan-range", text: "21 Sep – 18 Oct 2026"
  end

  test "tabs switch views and keep the address bar in sync" do
    sign_in_and_visit "projects"

    find(".plan-tabs button", text: ui("tabs.team")).click
    assert_current_path(%r{/plan/team\?date=2026-09-21&zoom=day})
    assert_selector ".plan-row[data-row='#{person_key(@joe)}']"

    find(".plan-tabs button", text: ui("tabs.report")).click
    assert_current_path(%r{/plan/report})
    assert_selector ".plan-report"

    find(".plan-tabs button", text: ui("tabs.export")).click
    assert_current_path(%r{/plan/export})
    assert_selector ".plan-export"
    assert_no_selector ".plan-range", visible: :visible
  end

  test "a deep link opens the requested view, week and zoom" do
    sign_in_as @admin
    visit_plan "team", date: Date.new(2026, 11, 4), zoom: "week"

    assert_selector ".plan-tabs [aria-selected='true']", text: ui("tabs.team")
    assert_selector ".plan-segment .is-active", text: ui("zoom.week")
    assert_selector ".plan-range", text: "2 Nov 2026 – 21 Feb 2027"
  end

  test "previous, next and today move the window a week at a time in day zoom" do
    sign_in_and_visit

    click_on ui("nav.next")
    assert_selector ".plan-range", text: "28 Sep – 25 Oct 2026"
    assert_current_path(/date=2026-09-28/)

    click_on ui("nav.previous")
    click_on ui("nav.previous")
    assert_selector ".plan-range", text: "14 Sep – 11 Oct 2026"

    click_on ui("nav.today")
    assert_selector ".plan-range", text: "21 Sep – 18 Oct 2026"
  end

  test "zooming changes the span and the header" do
    sign_in_and_visit

    assert_selector ".plan-tick", count: 28
    assert_selector ".plan-tick.is-today", text: "23"

    click_on ui("zoom.week")
    assert_selector ".plan-range", text: "21 Sep 2026 – 10 Jan 2027"
    assert_selector ".plan-tick", count: 16
    assert_selector ".plan-tick", text: "#{ui('week_short')}39"

    click_on ui("zoom.month")
    assert_selector ".plan-range", text: "21 Sep 2026 – 19 Sep 2027"
    assert_selector ".plan-tick", count: 52

    click_on ui("nav.next")
    assert_selector ".plan-range", text: "21 Dec 2026 – 19 Dec 2027"
  end

  test "keyboard shortcuts navigate unless the user is typing" do
    sign_in_and_visit

    find("body").send_keys(:arrow_right)
    assert_selector ".plan-range", text: "28 Sep – 25 Oct 2026"
    find("body").send_keys(:arrow_left)
    find("body").send_keys(:arrow_left)
    assert_selector ".plan-range", text: "14 Sep – 11 Oct 2026"
    find("body").send_keys("t")
    assert_selector ".plan-range", text: "21 Sep – 18 Oct 2026"

    find(".plan-search-input").send_keys("t", :arrow_right)
    assert_selector ".plan-range", text: "21 Sep – 18 Oct 2026"
  end

  test "only assignments in the visible window are loaded; navigating fetches more" do
    later = schedule!(@joe, @crm, MONDAY + 35, MONDAY + 39, 4)
    sign_in_and_visit
    expand person_key(@joe)

    assert_no_selector ".plan-bar[data-assignment-id='#{later.id}']"

    click_on ui("nav.next")
    click_on ui("nav.next")
    assert_selector ".plan-bar[data-assignment-id='#{later.id}']"
  end

  test "today is marked in the header and with a line through the grid" do
    sign_in_and_visit

    assert_selector ".plan-tick.is-today", text: "23"
    assert_selector ".plan-today-line"

    click_on ui("nav.next")
    click_on ui("nav.next")
    click_on ui("nav.next")
    click_on ui("nav.next")
    assert_no_selector ".plan-today-line"
  end
end
