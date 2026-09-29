require "application_system_test_case"

# Shared setup for the Plan module's browser tests. The clock is frozen on a
# Wednesday so dates, "today" and the visible window are the same on every run;
# the Elm app takes "today" from the server, so this also freezes the frontend.
class PlanSystemTestCase < ApplicationSystemTestCase
  MONDAY = Date.new(2026, 9, 21)
  TODAY = MONDAY + 2

  setup do
    travel_to TODAY.in_time_zone.change(hour: 10)
    @organization = organizations(:organization_one)
    @admin = users(:organization_admin)
    @joe = users(:joe)
    @member = users(:organization_user) # has access to project_1 only
    @crm = projects(:project_1)
    @billing = projects(:project_2)
  end

  teardown { travel_back }

  private

  # ---- data ------------------------------------------------------------

  def schedule!(assignee, project, from, to, hours, notes: nil)
    attributes = { project: project, start_date: from, end_date: to, minutes_per_day: (hours * 60).round, notes: notes }
    assignee.is_a?(Plan::Placeholder) ? attributes[:placeholder] = assignee : attributes[:user] = assignee
    @organization.plan_assignments.create!(attributes)
  end

  def placeholder!(name, roles: nil)
    @organization.plan_placeholders.create!(name: name, roles: roles)
  end

  # ---- navigation --------------------------------------------------------

  def sign_in_and_visit(view = "team", as: @admin, **options)
    sign_in_as as
    visit_plan(view, **options)
  end

  def visit_plan(view = "team", date: MONDAY, zoom: nil)
    visit plan_schedule_path(view: view, date: date.iso8601, zoom: zoom)
    assert_selector ".plan-app .plan-head"
    assert_no_selector ".plan-app.plan-loading"
  end

  def ui(key, **interpolations)
    I18n.t("plan.ui.#{key}", **interpolations)
  end

  # ---- rows and bars -------------------------------------------------------

  def person_key(user) = "u#{user.id}"
  def placeholder_key(placeholder) = "ph#{placeholder.id}"
  def project_key(project) = project ? "p#{project.id}" : "p-timeoff"

  def row(key)
    find(".plan-row[data-row='#{key}']")
  end

  def expand(key)
    row(key).find(".plan-expand").click
    assert_selector ".plan-row[data-row='#{key}'] .plan-expand[aria-expanded='true']"
  end

  def bar(assignment)
    find(".plan-bar[data-assignment-id='#{assignment.id}']")
  end

  def heat(key, date)
    row(key).find(".plan-heat[data-date='#{date.iso8601}']")
  end

  def day_width
    evaluate_script("parseFloat(getComputedStyle(document.querySelector('.plan-grid')).getPropertyValue('--dw'))")
  end

  # Horizontal centre of a date inside a timeline, as a Selenium offset from
  # the element's centre.
  def offset_for(timeline, day_index)
    (day_index * day_width + day_width / 2 - timeline.native.rect.width / 2).round
  end

  def actions
    page.driver.browser.action
  end

  # Real pointer drag of a bar (or its handle) by a number of days.
  def drag_bar(element, days, alt: false)
    element = element.native if element.respond_to?(:native)
    chain = actions.move_to(element)
    chain = chain.key_down(:alt) if alt
    chain = chain.click_and_hold.move_by((days * day_width / 2).round, 0).move_by((days * day_width / 2).round, 0).release
    chain = chain.key_up(:alt) if alt
    chain.perform
    assert_no_selector ".plan-app.plan-dragging"
  end

  def drag_handle(assignment, side, days)
    drag_bar(bar(assignment).find(".plan-handle-#{side}", visible: :all), days)
  end

  # Click and drag across empty days of a child row to draw a new assignment.
  def draw_assignment(row_key, from:, to:)
    timeline = row(row_key).find(".plan-timeline")
    start_index = (from - MONDAY).to_i
    actions.move_to(timeline.native, offset_for(timeline, start_index), 0)
      .click_and_hold
      .move_by(((to - from).to_i * day_width).round, 0)
      .release
      .perform
    assert_selector ".plan-modal"
  end

  # A click that the app sees as a click, not a drag.
  def click_bar(assignment)
    bar(assignment).click
    assert_selector ".plan-modal"
  end

  # ---- modals ---------------------------------------------------------------

  def within_modal(&block)
    within(".plan-modal", &block)
  end

  def hours_per_day_field = find("input[step='0.25'][min='0.25']")
  def total_hours_field = find("input[type=number][min='0']")
  def date_fields = all("input[type=date]").reject { |field| field.ancestor(".plan-field, .plan-split", match: :first)[:class].include?("plan-split") }

  def set_date(field, date)
    field.fill_in(with: date)
  end

  def save_modal
    find("button[type=submit]").click
  end

  def assert_toast(key)
    assert_selector ".plan-toast", text: ui("toast.#{key}")
  end

  # Saving happens asynchronously in the browser; poll the database briefly.
  # (Monotonic clock: Time.now is frozen by travel_to.)
  def assert_eventually(message = "condition never became true", timeout: Capybara.default_max_wait_time)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    until yield
      flunk message if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
      sleep 0.1
    end
    pass
  end
end
