require "test_helper"

class UserScoreTest < ActiveSupport::TestCase
  setup do
    @user = users(:joe)
    @organization = organizations(:organization_one)
    @project = projects(:project_1)
    @assigned_task = assigned_task(:task_1)
  end

  test "user tracks hours every single day gets perfect score" do
    @user.time_regs.destroy_all

    end_date = Date.current
    start_date = 4.weeks.ago.to_date.beginning_of_week

    (start_date..end_date).each do |date|
      next if date.saturday? || date.sunday?

      @user.time_regs.create!(
        date_worked: date,
        minutes: 480,
        assigned_task: @assigned_task,
        notes: "Daily work",
        created_at: date,
        updated_at: date
      )
    end

    score = @user.score(weeks_back: 4)
    assert_equal 1.0, score, "User tracking every day should have perfect score"
  end

  test "user tracks hours for 4 weeks all at once gets penalty" do
    @user.time_regs.destroy_all

    end_date = Date.current
    start_date = 4.weeks.ago.to_date.beginning_of_week

    (start_date..end_date).each do |date|
      next if date.saturday? || date.sunday?

      @user.time_regs.create!(
        date_worked: date,
        minutes: 480,
        assigned_task: @assigned_task,
        notes: "Batch entry",
        created_at: Date.current,
        updated_at: Date.current
      )
    end

    score = @user.score(weeks_back: 4)
    assert_in_delta 0.5, score, 0.05, "User tracking all at once should get approximately 0.5 score"
  end

  test "user has not tracked any hours gets zero score" do
    @user.time_regs.destroy_all

    score = @user.score(weeks_back: 4)
    assert_equal 0.0, score, "User with no time entries should have zero score"
  end

  test "user gets bonus score for adding notes to time entries" do
    @user.time_regs.destroy_all

    end_date = Date.current
    start_date = 4.weeks.ago.to_date.beginning_of_week

    (start_date..end_date).each do |date|
      next if date.saturday? || date.sunday?

      @user.time_regs.create!(
        date_worked: date,
        minutes: 480,
        assigned_task: @assigned_task,
        notes: "Detailed description of work performed today",
        created_at: date,
        updated_at: date
      )
    end

    score = @user.score(weeks_back: 4)
    assert_equal 1.0, score, "User tracking daily with notes should have perfect score (0.8 + 0.2 bonus)"
  end
end
