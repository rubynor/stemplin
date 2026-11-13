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
  class MonthLock < ActiveSupport::TestCase
    setup do
      @user = users(:organization_user)
      @task = assigned_task(:task_1)
      @other_org_task = assigned_task(:org_two_task)
      @last = Date.current.last_month
      @locked_reg = @user.time_regs.create!(assigned_task: @task, minutes: 30, date_worked: @last.beginning_of_month + 4)
      @open_reg = @user.time_regs.create!(assigned_task: @task, minutes: 30, date_worked: Date.current)
      TimeLock.create!(organization: organizations(:organization_one), user: @user,
                       locked_by: users(:organization_admin), period: @last.beginning_of_month)
    end

    def last = @last

    test "cannot create an entry in a locked month" do
      reg = @user.time_regs.new(assigned_task: @task, minutes: 60, date_worked: last.end_of_month)
      assert_not reg.save
      assert_includes reg.errors[:base].first, I18n.l(last, format: "%B %Y")
    end

    test "can create an entry on the first day after a locked month" do
      assert @user.time_regs.new(assigned_task: @task, minutes: 60, date_worked: last.end_of_month + 1).save
    end

    test "cannot edit, move out of, move into, or discard an entry in a locked month" do
      assert_not @locked_reg.update(minutes: 5)
      assert_not @locked_reg.update(date_worked: Date.current)
      assert_not @open_reg.update(date_worked: last.beginning_of_month)
      assert_not @locked_reg.discard
      assert @locked_reg.reload.kept?
    end

    test "cannot destroy an entry in a locked month" do
      assert_not @locked_reg.destroy
      assert TimeReg.exists?(@locked_reg.id)
    end

    test "discard! raises for an entry in a locked month" do
      assert_raises(Discard::RecordNotDiscarded) { @locked_reg.discard! }
      assert_includes @locked_reg.errors[:base].first, I18n.l(last, format: "%B %Y")
    end

    test "cannot move an entry to a task in a locked organization month" do
      other = @user.time_regs.create!(assigned_task: @other_org_task, minutes: 5, date_worked: last.end_of_month)
      assert_not other.update(assigned_task: @task)
    end

    test "cannot move a locked entry to another user" do
      assert_not @locked_reg.update(user: users(:joe))
      assert_equal @user.id, @locked_reg.reload.user_id
    end

    test "cannot move an entry into another user's locked month by changing its user" do
      reg = users(:joe).time_regs.create!(assigned_task: @task, minutes: 15, date_worked: last.end_of_month)
      assert_not reg.update(user: @user)
      assert_includes reg.errors[:base].first, I18n.l(last, format: "%B %Y")
    end

    test "moving an entry across organizations checks only its old and new state" do
      reg = @user.time_regs.create!(assigned_task: @task, minutes: 15, date_worked: Date.current)
      assert reg.update(assigned_task: @other_org_task, date_worked: last.end_of_month)
    end

    test "cannot undiscard an entry into a locked month" do
      reg = @user.time_regs.create!(assigned_task: @task, minutes: 15, date_worked: Date.current)
      reg.discard!
      reg.update_columns(date_worked: last.end_of_month)
      assert_not reg.undiscard
      assert reg.reload.discarded?
      assert_raises(Discard::RecordNotUndiscarded) { reg.undiscard! }
    end

    test "can undiscard an entry outside a locked month" do
      reg = @user.time_regs.create!(assigned_task: @task, minutes: 15, date_worked: Date.current)
      reg.discard!
      assert reg.undiscard
    end

    test "a lock in one organization does not block the user's entries in another" do
      assert @user.time_regs.new(assigned_task: @other_org_task, minutes: 60, date_worked: last.end_of_month).save
    end

    test "another user's entries in the same month are not blocked" do
      assert users(:joe).time_regs.new(assigned_task: @task, minutes: 60, date_worked: last.end_of_month).save
    end

    test "an entry on a since-deleted project is still protected" do
      @locked_reg.project.discard
      assert_not TimeReg.find(@locked_reg.id).update(minutes: 5)
    end

    test "#organization_id_for_lock ignores soft-deleted project and client" do
      expected = organizations(:organization_one).id
      assert_equal expected, @locked_reg.organization_id_for_lock
      client = @locked_reg.client
      @locked_reg.project.discard
      client.discard
      assert_equal expected, TimeReg.find(@locked_reg.id).organization_id_for_lock
    end
  end
end
