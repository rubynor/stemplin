require_relative "plan_system_test_case"

class Plan::PeopleAndPlaceholdersTest < PlanSystemTestCase
  def open_person_dialog(user)
    row(person_key(user)).hover
    row(person_key(user)).find(".plan-row-action").click
    assert_selector ".plan-modal", text: user.email
  end

  test "a placeholder is added from the team view" do
    sign_in_and_visit
    click_on "+ #{ui('add_placeholder')}"

    within_modal do
      assert_text ui("placeholder_form.new_title")
      all("input")[0].fill_in(with: "QA engineer")
      all("input")[1].fill_in(with: "Automation")
      save_modal
    end

    assert_toast "placeholder_saved"
    placeholder = @organization.plan_placeholders.sole
    assert_equal [ "QA engineer", "Automation" ], [ placeholder.name, placeholder.roles ]
    within(row(placeholder_key(placeholder))) do
      assert_text "QA engineer"
      assert_text "Automation"
      assert_selector ".plan-avatar-placeholder"
    end
  end

  test "a placeholder needs a name" do
    sign_in_and_visit
    click_on "+ #{ui('add_placeholder')}"

    within_modal do
      save_modal
      assert_selector ".plan-form-error", text: ui("errors.name_required")
    end
    assert_equal 0, Plan::Placeholder.count
  end

  test "placeholders are renamed" do
    designer = placeholder!("Designer")
    sign_in_and_visit
    row(placeholder_key(designer)).hover
    row(placeholder_key(designer)).find(".plan-row-action").click

    within_modal do
      assert_text ui("placeholder_form.edit_title")
      all("input")[0].fill_in(with: "Senior designer")
      save_modal
    end

    assert_toast "placeholder_saved"
    assert_eventually { designer.reload.name == "Senior designer" }
    within(row(placeholder_key(designer))) { assert_text "Senior designer" }
  end

  test "deleting a placeholder removes its assignments too, after confirmation" do
    designer = placeholder!("Designer")
    booked = schedule!(designer, @crm, MONDAY, MONDAY + 4, 6)
    sign_in_and_visit "projects"
    assert_selector ".plan-bar[data-assignment-id='#{booked.id}']"
    find(".plan-tabs button", text: ui("tabs.team")).click

    row(placeholder_key(designer)).hover
    row(placeholder_key(designer)).find(".plan-row-action").click
    within_modal do
      click_on ui("delete")
      click_on ui("confirm_delete")
    end

    assert_toast "placeholder_deleted"
    assert_no_selector ".plan-row[data-row='#{placeholder_key(designer)}']"
    assert_not Plan::Assignment.exists?(booked.id)
    find(".plan-tabs button", text: ui("tabs.projects")).click
    assert_no_selector ".plan-bar[data-assignment-id='#{booked.id}']"
  end

  test "work drawn for a placeholder can later be handed to a person" do
    designer = placeholder!("Designer")
    booked = schedule!(designer, @crm, MONDAY + 7, MONDAY + 11, 6)
    sign_in_and_visit
    expand placeholder_key(designer)
    click_bar booked

    within_modal do
      all("select")[1].select(@joe.name)
      save_modal
    end

    assert_toast "assignment_saved"
    assert_eventually { booked.reload.user == @joe }
    assert_nil booked.placeholder
  end

  test "an admin changes someone's weekly capacity" do
    schedule!(@joe, @crm, MONDAY, MONDAY + 4, 4)
    sign_in_and_visit
    open_person_dialog @joe

    within_modal do
      assert_equal "37.5", find("input[type=number]").value
      assert_text ui("person.per_day", hours: "7.5")
      find("input[type=number]").fill_in(with: "30")
      assert_text ui("person.per_day", hours: "6")
      save_modal
    end

    assert_toast "person_saved"
    assert_eventually { access_infos(:access_info_1).reload.plan_weekly_capacity_minutes == 1800 }
    within(row(person_key(@joe))) { assert_text ui("capacity_per_week", hours: "30") }
    assert_equal "2", heat(person_key(@joe), MONDAY).text
  end

  test "working days are toggled per person and the heatmap follows" do
    sign_in_and_visit
    assert_selector ".plan-row[data-row='#{person_key(@joe)}'] .plan-heat[data-date='#{(MONDAY + 4).iso8601}']"
    open_person_dialog @joe

    within_modal do
      friday = all(".plan-day-toggle")[4]
      assert_equal "true", friday["aria-pressed"]
      assert_selector ".plan-day-toggle[aria-pressed='false']", count: 2 # the weekend
      friday.click
      assert_selector ".plan-day-toggle[aria-pressed='false']", count: 3
      assert_text ui("person.per_day", hours: "9.38")
      save_modal
    end

    assert_toast "person_saved"
    assert_eventually { access_infos(:access_info_1).reload.plan_work_days == 0b0001111 }
    assert_no_selector ".plan-row[data-row='#{person_key(@joe)}'] .plan-heat[data-date='#{(MONDAY + 4).iso8601}']"
    assert_equal "9.38", heat(person_key(@joe), MONDAY).text
  end

  test "an invalid capacity is refused" do
    sign_in_and_visit
    open_person_dialog @joe

    within_modal do
      find("input[type=number]").fill_in(with: "-5")
      save_modal
      assert_selector ".plan-form-error", text: ui("errors.hours_invalid")
    end
    assert_nil access_infos(:access_info_1).reload.plan_weekly_capacity_minutes
  end

  test "new assignments default to the person's working day" do
    access_infos(:access_info_1).update!(plan_weekly_capacity_minutes: 1200) # 20h over five days
    schedule!(@joe, @crm, MONDAY, MONDAY, 1)
    sign_in_and_visit
    expand person_key(@joe)
    draw_assignment "#{person_key(@joe)}-#{@crm.id}", from: MONDAY + 7, to: MONDAY + 8

    within_modal { assert_equal "4", hours_per_day_field.value }
  end

  test "the invite link goes to the team member invitations" do
    sign_in_and_visit
    click_on ui("invite_people")

    assert_current_path invite_users_workspace_team_members_path
  end
end
