require 'test_helper'

class TimeRegTest < ActiveSupport::TestCase
  test "#report scoped data" do

    clients = [clients(:e_corp)].map(&:id)
    projects = [projects(:project_1)].map(&:id)
    users = [users(:joe)].map(&:id)
    tasks = [tasks(:debug)].map(&:id)

    regs = TimeReg.with_report_scope(clients, projects, users, tasks)

    assert_equal 1, regs.count
    assert_equal [time_regs(:time_reg_1)], regs.to_a

  end
end
