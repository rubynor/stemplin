require_relative "plan_system_test_case"

class Plan::ReportAndExportTest < PlanSystemTestCase
  setup do
    TimeReg.unscoped.delete_all
    # Two weeks of CRM at 4h/day (40h; 12h of it Mon–Wed of this week) and two days off.
    schedule!(@joe, @crm, MONDAY, MONDAY + 11, 4)
    schedule!(@joe, nil, MONDAY + 14, MONDAY + 15, 7.5)
    task = assigned_task(:task_1)
    TimeReg.create!(user: @joe, assigned_task: task, date_worked: MONDAY, minutes: 240)
    TimeReg.create!(user: @joe, assigned_task: task, date_worked: MONDAY + 1, minutes: 300)
  end

  def report_row(table_heading, label)
    card = find(".surface-card", text: table_heading)
    card.find("tbody tr", text: label)
  end

  def cells(tr) = tr.all("td").map(&:text)

  test "people: capacity, time off, planned, planned to date, tracked and utilization" do
    sign_in_and_visit "report"

    assert_text ui("report.intro", range: "21 Sep – 18 Oct 2026")
    joe = cells(report_row(ui("report.people"), @joe.name))
    # 20 working days × 7.5h; available after time off is 135h; 40 / 135 = 30%
    assert_equal [ "JD\n#{@joe.name}", "150h", "15h", "40h", "12h", "9h", "30%" ], joe
  end

  test "people who are overbooked show a red meter" do
    schedule!(@member, @crm, MONDAY, MONDAY + 27, 9)
    sign_in_and_visit "report"

    member = report_row(ui("report.people"), @member.name)
    assert_equal "120%", cells(member).last
    assert member.has_selector?(".plan-meter-fill.is-over")
  end

  test "projects: planned against tracked so far" do
    sign_in_and_visit "report"

    assert_equal [ "#{clients(:e_corp).name}\n#{@crm.name}", "40h", "12h", "9h", "-3h" ], cells(report_row(ui("report.projects"), @crm.name))
    assert_no_selector ".surface-card tbody tr", text: @billing.name
  end

  test "the report follows the visible window" do
    sign_in_and_visit "report"
    click_on ui("nav.next")
    click_on ui("nav.next")
    click_on ui("nav.next")

    assert_text ui("report.intro", range: "12 Oct – 8 Nov 2026")
    assert_equal "0h", cells(report_row(ui("report.people"), @joe.name))[3]
    assert_text ui("report.no_projects")
  end

  test "the export link follows the chosen options" do
    sign_in_and_visit "export"
    assert_selector "a[href*='view=projects&period=weekly&start=2026-09-21&end=2027-01-10']", text: ui("export.download")

    choose ui("export.team")
    choose ui("export.monthly")
    find("#plan-export-timeframe").select(ui("export.this_month"))
    assert_selector "a[href*='view=team&period=monthly&start=2026-08-31&end=2026-10-04']", text: ui("export.download")

    find("#plan-export-timeframe").select(ui("export.this_week"))
    assert_selector "a[href*='start=2026-09-21&end=2026-09-27']", text: ui("export.download")

    find("#plan-export-timeframe").select(ui("export.this_year"))
    assert_selector "a[href*='start=2025-12-29&end=2027-01-03']", text: ui("export.download")
  end

  test "a custom range is validated" do
    sign_in_and_visit "export"
    find("#plan-export-timeframe").select(ui("export.custom"))
    dates = all(".plan-export input[type=date]")

    dates[0].fill_in(with: MONDAY + 10)
    dates[1].fill_in(with: MONDAY)
    assert_text ui("errors.invalid_range")
    assert_no_link ui("export.download")

    dates[1].fill_in(with: MONDAY + 20)
    assert_selector "a[href*='start=2026-10-01&end=2026-10-11']", text: ui("export.download")
  end

  test "the downloaded CSV has the planned hours per person and week" do
    sign_in_and_visit "export"
    choose ui("export.team")
    find("#plan-export-timeframe").select(ui("export.two_weeks"))
    assert_selector "a[href*='start=2026-09-21&end=2026-10-04']", text: ui("export.download")

    csv = evaluate_async_script(<<~JS, find_link(ui("export.download"))[:href])
      fetch(arguments[0]).then(r => r.text()).then(arguments[1])
    JS
    rows = CSV.parse(csv)

    assert_equal [ "Person", "Client", "Project", "2026-09-21", "2026-09-28", "Total" ], rows.first
    assert_includes rows, [ @joe.name, clients(:e_corp).name, @crm.name, "20.0", "20.0", "40.0" ]
  end
end
