require "test_helper"

class TimeLockTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:organization_one)
    @user = users(:organization_user)
    @admin = users(:organization_admin)
    @last = Date.current.last_month.beginning_of_month
    @user.time_regs.create!(assigned_task: assigned_task(:task_1), minutes: 30, date_worked: @last + 1)
  end

  def build_lock(**attrs)
    TimeLock.new({ organization: @organization, user: @user, locked_by: @admin, period: @last }.merge(attrs))
  end

  test "is valid for last month" do
    assert build_lock.valid?
  end

  test "rejects a month without hours in the organization" do
    lock = build_lock(user: users(:joe))
    assert_not lock.valid?
    assert_includes lock.errors[:base], I18n.t("tripletex.locks.errors.no_hours")
  end

  test "hours in another organization do not count" do
    lock = build_lock(organization: organizations(:organization_two))
    assert_not lock.valid?
    assert_includes lock.errors[:base], I18n.t("tripletex.locks.errors.no_hours")
  end

  test "rejects the current month" do
    lock = build_lock(period: Date.current.beginning_of_month)
    assert_not lock.valid?
    assert lock.errors[:period].any?
  end

  test "rejects a period that is not the first of a month" do
    lock = build_lock(period: @last + 14)
    assert_not lock.valid?
    assert lock.errors[:period].any?
  end

  test "rejects a second lock for the same user, organization and month" do
    build_lock.save!
    assert_not build_lock.valid?
  end

  test "allows the same month for another user or organization" do
    users(:joe).time_regs.create!(assigned_task: assigned_task(:task_1), minutes: 30, date_worked: @last + 1)
    @user.time_regs.create!(assigned_task: assigned_task(:org_two_task), minutes: 30, date_worked: @last + 1)
    build_lock.save!
    assert build_lock(user: users(:joe)).valid?
    assert build_lock(organization: organizations(:organization_two)).valid?
  end

  test "rejects when a timer is running in the month" do
    task = assigned_task(:task_1)
    reg = @user.time_regs.create!(assigned_task: task, minutes: 10, date_worked: @last + 3)
    reg.update_columns(start_time: Time.current)

    lock = build_lock
    assert_not lock.valid?
    assert_includes lock.errors[:base], I18n.t("tripletex.locks.errors.timer_running")
  end

  test "a running timer in another month does not block" do
    task = assigned_task(:task_1)
    reg = @user.time_regs.create!(assigned_task: task, minutes: 10, date_worked: Date.current)
    reg.update_columns(start_time: Time.current)

    assert build_lock.valid?
  end

  test "locked? and for_period" do
    build_lock.save!
    assert TimeLock.locked?(organization_id: @organization.id, user_id: @user.id, date: @last + 10)
    assert_not TimeLock.locked?(organization_id: @organization.id, user_id: @user.id, date: Date.current)
    assert_not TimeLock.locked?(organization_id: @organization.id, user_id: users(:joe).id, date: @last)
    assert_equal 1, TimeLock.for_period(@last + 20).count
  end

  test "locked_by_other?" do
    assert build_lock.locked_by_other?
    assert_not build_lock(locked_by: @user).locked_by_other?
  end
end
