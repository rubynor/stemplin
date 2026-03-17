require "test_helper"

class TimeRegTest < ActiveSupport::TestCase
  def setup
    @time_reg = time_regs(:time_reg_1)
  end

  test "#report scoped data" do
    clients = [ clients(:e_corp) ].map(&:id)
    projects = [ projects(:project_1) ].map(&:id)
    users = [ users(:joe) ].map(&:id)
    tasks = [ tasks(:debug) ].map(&:id)

    regs = TimeReg.for_report(clients, projects, users, tasks)

    assert_equal 2, regs.count
    assert_includes regs, time_regs(:time_reg_1)
    assert_includes regs, time_regs(:time_reg_5)
  end

  test "#current_minutes" do
    assert_equal 120, @time_reg.current_minutes

    @time_reg.update(start_time: 20.minutes.ago)
    assert_equal 140, @time_reg.current_minutes
  end

  test "#used_rate for an assigned_task with a custom rate will return the assigned_task rate" do
    time_reg = time_regs(:time_reg_with_custom_rate_task_1)
    assert_equal time_reg.assigned_task.rate, time_reg.used_rate
  end

  test "#used_rate for an assigned_task with a rate of 0 will return the project rate" do
    @time_reg.assigned_task.update(rate: 0)
    assert_equal @time_reg.project.rate, @time_reg.used_rate
  end

  test "#total_hours should be accurate" do
    assert_equal @time_reg.minutes.to_f / 60, @time_reg.total_hours
  end

  test "#billed_amount should be accurate" do
    assert_equal @time_reg.total_hours * @time_reg.used_rate, @time_reg.billed_amount
  end

  test "#notes should allow line breaks" do
    @time_reg.notes = "First line \n second line"
    assert @time_reg.valid?
  end

  test "#minutes shold allow 0 while inactive" do
    @time_reg.minutes = 0
    @time_reg.start_time = nil
    @time_reg.save
    assert_not @time_reg.active?
  end

  # used_rate_for(organization)

  test "#used_rate_for returns same as used_rate when org is the project owner" do
    owner_org = organizations(:organization_one)
    assert_equal @time_reg.used_rate, @time_reg.used_rate_for(owner_org)
  end

  test "#used_rate_for returns the task rate when guest org has a ProjectShareTaskRate" do
    guest_org = organizations(:organization_two)
    task_rate = project_share_task_rates(:task_rate_one)
    assert_equal task_rate.rate, @time_reg.used_rate_for(guest_org)
  end

  test "#used_rate_for returns the project share rate when guest org has no task rate" do
    guest_org = organizations(:organization_two)
    project_share = project_shares(:project_one_shared_with_org_two)
    project_share.update!(rate: 200)
    project_share.project_share_task_rates.destroy_all

    assert_equal 200, @time_reg.used_rate_for(guest_org)
  end

  test "#used_rate_for returns 0 when guest org has no rates set" do
    guest_org = organizations(:organization_two)
    project_share = project_shares(:project_one_shared_with_org_two)
    project_share.update!(rate: 0)
    project_share.project_share_task_rates.destroy_all

    assert_equal 0, @time_reg.used_rate_for(guest_org)
  end

  # billed_amount_for(organization)

  test "#billed_amount_for returns minutes / 60.0 * used_rate_for(organization)" do
    guest_org = organizations(:organization_two)
    expected = @time_reg.minutes / 60.0 * @time_reg.used_rate_for(guest_org)
    assert_equal expected, @time_reg.billed_amount_for(guest_org)
  end
end
