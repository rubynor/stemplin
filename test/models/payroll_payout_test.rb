require "test_helper"

class PayrollPayoutTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:organization_one)
    @user = users(:organization_user)
    @admin = users(:organization_admin)
    @period = Date.current.last_month.beginning_of_month
  end

  def build_payout(**attrs)
    PayrollPayout.new({ organization: @organization, user: @user, period: @period, status: :unclear, minutes: 125, hours: 2.08,
                        hourly_wage: 250, amount: 520, tripletex_employee_id: 7, sent_by: @admin, created_at: 1.hour.ago }.merge(attrs))
  end

  def lock
    @user.time_regs.create!(assigned_task: assigned_task(:task_1), minutes: 30, date_worked: @period + 1)
    TimeLock.create!(organization: @organization, user: @user, locked_by: @admin, period: @period)
  end

  test "at most one payout per organization, user and month, enforced by the database" do
    build_payout.save!
    assert_raises(ActiveRecord::RecordNotUnique) { build_payout(status: :sent).save! }
    assert build_payout(period: @period.last_month).save
    assert build_payout(user: @admin).save
  end

  test "the period must be the first of a month" do
    assert_not build_payout(period: @period + 3).valid?
  end

  test "release! removes an unclear or stale pending payout" do
    [ :unclear, :pending ].each do |status|
      payout = build_payout(status: status)
      payout.save!
      payout.release!
      assert_not PayrollPayout.exists?(payout.id)
    end
  end

  test "release! refuses a sent payout" do
    payout = build_payout(status: :sent, sent_at: Time.current)
    payout.save!
    assert_raises(Payroll::Error) { payout.release! }
    assert PayrollPayout.exists?(payout.id)
  end

  test "a pending payout still being sent cannot be resolved" do
    payout = build_payout(status: :pending, created_at: Time.current)
    payout.save!
    assert_raises(Payroll::Error) { payout.release! }
    assert_raises(Payroll::Error) { payout.mark_sent!(by: @admin) }
    assert payout.reload.pending?
  end

  test "mark_sent! turns an unclear payout into a sent one and keeps who sent it" do
    payout = build_payout(sent_by: @user)
    payout.save!
    freeze_time do
      payout.mark_sent!(by: @admin)
      assert payout.reload.sent?
      assert_equal [ Time.current, @user ], [ payout.sent_at, payout.sent_by ]
    end
    assert_equal @admin.id.to_s, payout.versions.reorder(:id).last.whodunnit
  end

  test "mark_sent! refuses a sent payout" do
    sent_at = 2.days.ago.change(usec: 0)
    payout = build_payout(status: :sent, sent_at: sent_at)
    payout.save!
    assert_raises(Payroll::Error) { payout.mark_sent!(by: @admin) }
    assert_equal sent_at, payout.reload.sent_at
  end

  test "TimeLock#sent? is true for a payout of any status in the same organization, user and month" do
    time_lock = lock
    assert_not time_lock.sent?
    build_payout(user: @admin).save!
    build_payout(period: @period.last_month).save!
    assert_not time_lock.sent?
    %i[pending unclear sent].each do |status|
      PayrollPayout.where(user: @user, period: @period).delete_all
      build_payout(status: status).save!
      assert time_lock.sent?, status
    end
  end

  test "a lock with a payout cannot be destroyed" do
    time_lock = lock
    build_payout.save!
    assert_not time_lock.destroy
    assert_raises(ActiveRecord::RecordNotDestroyed) { time_lock.destroy! }
    assert TimeLock.exists?(time_lock.id)
  end
end
