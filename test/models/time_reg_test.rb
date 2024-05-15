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
end
