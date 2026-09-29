require_relative "plan_system_test_case"

# One realistic end-to-end story across the whole module: staff a project,
# rebalance, slip it, and check the numbers.
class Plan::JourneyTest < PlanSystemTestCase
  test "an admin plans a project from scratch" do
    schedule!(@joe, @crm, MONDAY, MONDAY, 1) # gives Joe a CRM row to draw in
    sign_in_and_visit

    # A placeholder until someone is hired, and Joe on CRM next week.
    click_on "+ #{ui('add_placeholder')}"
    within_modal do
      all("input")[0].fill_in(with: "Backend developer")
      save_modal
    end
    assert_toast "placeholder_saved"
    backend = @organization.plan_placeholders.sole

    expand person_key(@joe)
    draw_assignment "#{person_key(@joe)}-#{@crm.id}", from: MONDAY + 7, to: MONDAY + 11
    within_modal do
      hours_per_day_field.fill_in(with: "6")
      save_modal
    end
    assert_toast "assignment_saved"
    joe_week = @organization.plan_assignments.find_by!(user: @joe, start_date: MONDAY + 7)

    expand placeholder_key(backend)
    row("#{placeholder_key(backend)}-add").find("select").select(@crm.name)
    within_modal do
      set_date date_fields[0], MONDAY + 7
      set_date date_fields[1], MONDAY + 18
      save_modal
    end
    assert_toast "assignment_saved"

    # Joe is overbooked on Wednesday once Billing needs him too.
    row("#{person_key(@joe)}-add").find("select").select(@billing.name)
    within_modal do
      set_date date_fields[0], MONDAY + 9
      set_date date_fields[1], MONDAY + 9
      hours_per_day_field.fill_in(with: "3")
      save_modal
    end
    assert_toast "assignment_saved"
    assert_selector ".plan-row[data-row='#{person_key(@joe)}'] .plan-heat.is-over[data-date='#{(MONDAY + 9).iso8601}']"

    # …so his CRM week shrinks by one hour a day.
    click_bar joe_week
    within_modal do
      hours_per_day_field.fill_in(with: "4.5")
      save_modal
    end
    assert_toast "assignment_saved"
    assert_selector ".plan-row[data-row='#{person_key(@joe)}'] .plan-heat.is-full[data-date='#{(MONDAY + 9).iso8601}']"

    # The project slips a week.
    find(".plan-tabs button", text: ui("tabs.projects")).click
    row(project_key(@crm)).hover
    row(project_key(@crm)).find(".plan-row-action").click
    within_modal do
      shift = all(".plan-shift input[type=date]")
      shift[0].fill_in(with: MONDAY + 7)
      shift[1].fill_in(with: MONDAY + 14)
      click_on ui("project.shift")
    end
    assert_toast "timeline_shifted"
    assert_eventually { joe_week.reload.start_date == MONDAY + 14 }

    # The report covers the visible four weeks. Joe: 1h + 4.5h×5 on CRM + 3h Billing.
    # CRM: Joe's 23.5h plus the placeholder's 7.5h × 10 days, now in weeks 3–4.
    find(".plan-tabs button", text: ui("tabs.report")).click
    joe = find(".surface-card", text: ui("report.people")).find("tbody tr", text: @joe.name)
    assert_equal "26.5h", joe.all("td")[3].text
    crm = find(".surface-card", text: ui("report.projects")).find("tbody tr", text: @crm.name)
    assert_equal "98.5h", crm.all("td")[1].text
  end
end
