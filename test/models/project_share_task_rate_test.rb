require "test_helper"

class ProjectShareTaskRateTest < ActiveSupport::TestCase
  def setup
    @project_share = project_shares(:project_one_shared_with_org_two)
    @assigned_task = assigned_task(:task_1)
  end

  test "valid project share task rate" do
    rate = ProjectShareTaskRate.new(
      project_share: @project_share,
      assigned_task: assigned_task(:task_2),
      rate: 300
    )
    assert rate.valid?
  end

  test "belongs to project_share" do
    rate = project_share_task_rates(:task_rate_one)
    assert_instance_of ProjectShare, rate.project_share
  end

  test "belongs to assigned_task" do
    rate = project_share_task_rates(:task_rate_one)
    assert_instance_of AssignedTask, rate.assigned_task
  end

  test "validates uniqueness of assigned_task_id scoped to project_share_id" do
    existing = project_share_task_rates(:task_rate_one)
    duplicate = ProjectShareTaskRate.new(
      project_share: existing.project_share,
      assigned_task: existing.assigned_task,
      rate: 500
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:assigned_task_id], "has already been taken"
  end

  test "includes RateConvertible" do
    assert_includes ProjectShareTaskRate.ancestors, RateConvertible
  end

  test "rate_currency getter converts hundredths to currency format" do
    rate = ProjectShareTaskRate.new(rate: 350)
    assert_equal "3,50", rate.rate_currency
  end

  test "rate_currency setter converts currency format to hundredths" do
    rate = ProjectShareTaskRate.new
    rate.rate_currency = "4,25"
    assert_equal 425, rate.rate
  end

  test "rate defaults to 0" do
    rate = ProjectShareTaskRate.new(
      project_share: @project_share,
      assigned_task: @assigned_task
    )
    assert_equal 0, rate.rate
  end
end
