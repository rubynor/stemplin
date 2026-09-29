require_relative "plan_system_test_case"

class Plan::LocalizationAndLayoutTest < PlanSystemTestCase
  test "the plan speaks Norwegian to Norwegian users" do
    @admin.update!(locale: "nb")
    schedule!(@joe, nil, MONDAY, MONDAY, 7.5)
    # The sign-in page is still English; the user's language applies once signed in.
    visit new_user_session_path
    fill_in "user[email]", with: @admin.email
    fill_in "user[password]", with: "password"
    click_button I18n.t("login_page.sign_in")
    assert_text I18n.t("devise.sessions.signed_in", locale: :nb)
    I18n.with_locale(:nb) do
      visit_plan "projects"

      assert_selector ".plan-tabs", text: "Prosjekter"
      assert_selector ".plan-tabs", text: "Planlagt mot ført"
      assert_selector ".plan-segment", text: "Uker"
      assert_selector ".plan-range", text: "21 Sep – 18 Okt 2026"
      assert_selector ".plan-month", text: "OKT 2026"
      assert_equal %w[M T O T F L S], all(".plan-tick-day").first(7).map(&:text)
      assert_selector ".plan-row[data-row='p-timeoff']", text: "Fravær"
      assert_selector ".plan-search-input[placeholder='Søk etter personer eller prosjekter…']"

      find(".plan-tabs button", text: "Team").click
      click_on "+ Legg til plassholder"
      within_modal do
        assert_text "Ny plassholder"
        all("input")[0].fill_in(with: "Designer")
        click_on "Lagre plassholder"
      end
      assert_selector ".plan-toast", text: "Plassholderen er lagret"
    end
  end

  test "switching language from the plan keeps the user on a working plan" do
    schedule!(@joe, @crm, MONDAY, MONDAY, 7.5)
    sign_in_and_visit "projects"
    page.driver.browser.logs.get(:browser)

    # Redirecting back to the same page makes Turbo morph it in place, which
    # must not touch the markup Elm owns.
    find("nav", text: I18n.t("language.name")).find("span", text: I18n.t("language.name"), match: :first).click
    click_on I18n.t("language.name", locale: :nb)

    assert_selector ".plan-tabs", text: "Planlagt mot ført"
    assert_selector ".plan-range", text: "21 Sep – 18 Okt 2026"
    assert_selector ".plan-row[data-row='#{project_key(@crm)}']"
    assert_equal "nb", @admin.reload.locale

    # Only the new app may react to the keyboard.
    find(".plan-tabs button", text: "Team").click
    assert_selector ".plan-row[data-row='#{person_key(@joe)}']"
    data_requests = -> { evaluate_script("performance.getEntriesByType('resource').filter((entry) => entry.name.includes('/plan/data')).length") }
    before = data_requests.call
    find("body").send_keys(:arrow_right)
    assert_selector ".plan-range", text: "28 Sep – 25 Okt 2026"
    assert_no_selector ".plan-app.plan-loading"
    assert_equal 1, data_requests.call - before, "more than one plan app is still running"
    assert_current_path plan_schedule_path(view: "team", date: (MONDAY + 7).iso8601, zoom: "day")
    errors = page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    assert_empty errors.map(&:message)
  end

  test "on a phone the schedule scrolls inside its card and never widens the page" do
    schedule!(@joe, @crm, MONDAY, MONDAY + 20, 4)
    sign_in_as @admin
    page.driver.browser.manage.window.resize_to(390, 844)
    visit_plan "team"

    assert_selector ".plan-row[data-row='#{person_key(@joe)}']"
    assert evaluate_script("document.documentElement.scrollWidth <= window.innerWidth"), "the page itself scrolls sideways"
    assert evaluate_script("document.querySelector('.plan-scroll').scrollWidth > document.querySelector('.plan-scroll').clientWidth")
    assert_equal 180, evaluate_script("document.querySelector('.plan-left').getBoundingClientRect().width").round
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  test "the left column stays in view while the timeline scrolls" do
    sign_in_as @admin
    page.driver.browser.manage.window.resize_to(900, 900)
    visit_plan "team"

    left = -> { evaluate_script("document.querySelector(\".plan-row[data-row='#{person_key(@joe)}'] .plan-left\").getBoundingClientRect().left") }
    before = left.call
    execute_script("document.querySelector('.plan-scroll').scrollLeft = 400")
    assert_in_delta before, left.call, 1
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
