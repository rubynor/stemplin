require "test_helper"

class Plan::AssignmentTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:organization_one)
    @project = projects(:project_1)
    @user = users(:joe)
    @monday = Date.new(2026, 9, 21)
  end

  def build(**attributes)
    @organization.plan_assignments.new({ project: @project, user: @user, start_date: @monday, end_date: @monday + 4, minutes_per_day: 240 }.merge(attributes))
  end

  test "is valid with a person, a project and a date range" do
    assert build.valid?
  end

  test "an assignment without a project is time off" do
    assert build(project: nil).time_off?
  end

  test "needs exactly one of person or placeholder" do
    placeholder = @organization.plan_placeholders.create!(name: "Designer")

    assert_not build(user: nil).valid?
    assert_not build(placeholder: placeholder).valid?
    assert build(user: nil, placeholder: placeholder).valid?
  end

  test "the end date cannot be before the start date" do
    assignment = build(end_date: @monday - 1)

    assert_not assignment.valid?
    assert assignment.errors.added?(:end_date, :before_start)
  end

  test "rejects hours outside a day" do
    assert_not build(minutes_per_day: 0).valid?
    assert_not build(minutes_per_day: 1441).valid?
  end

  test "project, person and placeholder must belong to the organization" do
    assert_not build(project: projects(:org_two_project)).valid?
    assert_not build(user: users(:org_admin_without_org)).valid?

    foreign_placeholder = organizations(:organization_two).plan_placeholders.create!(name: "Elsewhere")
    assert_not build(user: nil, placeholder: foreign_placeholder).valid?
  end

  test "counts only the assignee's working days" do
    assignment = build(end_date: @monday + 13) # two full weeks
    assignment.save!

    assert_equal 10, assignment.working_days_between
    assert_equal 5 * 240, assignment.minutes_between(@monday + 7, @monday + 20)

    access_infos(:access_info_1).update!(plan_work_days: 0b0000111) # Mon–Wed
    assert_equal 6, assignment.reload.working_days_between
  end

  test "split cuts the assignment in two at the given date" do
    assignment = build
    assignment.save!

    second = assignment.split!(@monday + 3)

    assert_equal [ @monday, @monday + 2 ], [ assignment.start_date, assignment.end_date ]
    assert_equal [ @monday + 3, @monday + 4 ], [ second.start_date, second.end_date ]
    assert_equal assignment.minutes_per_day, second.minutes_per_day
  end

  test "split refuses a date outside the assignment" do
    assignment = build
    assignment.save!

    assert_raises(ArgumentError) { assignment.split!(@monday) }
    assert_raises(ArgumentError) { assignment.split!(@monday + 5) }
  end
end
