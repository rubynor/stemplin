class TimeRegPresenterTest < ActiveSupport::TestCase
  def setup
    @time_regs = Project.first.time_regs

    @result = TimeRegsPresenter.new(@time_regs).report_data(
      title: "Project report",
      keys: [ :project, :task, :user ]
    )

    @time_regs_project_names = @time_regs.map(&:project).uniq.map(&:name).sort
    @time_regs_user_names = @time_regs.map(&:user).uniq.map(&:name).sort
    @time_regs_task_names = @time_regs.map(&:task).uniq.map(&:name).sort
  end

  test "#report_data has correct title" do
    assert_equal @result[:title], "Project report"
  end

  test "#report_data has correct total minutes" do
    time_regs_total_minutes = @time_regs.sum(&:minutes)
    assert_equal @result[:total], time_regs_total_minutes
  end

  test "#report_data base case has no children" do
    base_child = TimeRegsPresenter.new(@time_regs).report_data(title: "Project report", keys: [])
    assert_empty base_child[:children]
  end

  test "#report_data recursive case has grate grandchildren" do
    assert_instance_of Array, @result[:children]
    assert_not_empty @result[:children].first[:children].first[:children]
  end

  test "#report_data minutes sums up" do
    total_minutes = @result[:children].sum do |child| # Projects
      child[:children].sum do |child| # Tasks
        child[:children].sum do |child| # Users
          child[:minutes]
        end
      end
    end

    assert_equal total_minutes, @result[:total]
  end

  test "#time_reg_report handles blank keys" do
    time_reg_hashes = TimeRegsPresenter.new(@time_regs).as_hashes
    children = TimeRegsPresenter.new(@time_regs).time_reg_report(time_reg_hashes, [])
    assert_empty children
  end
end
