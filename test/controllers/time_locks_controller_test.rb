require "test_helper"

class TimeLocksControllerTest < ActionController::TestCase
  setup do
    @organization = organizations(:organization_one)
    @member = users(:organization_user)
    @admin = users(:organization_admin)
    @last = Date.current.last_month.beginning_of_month
    @month = @last.strftime("%Y-%m")
    @organization.create_tripletex_integration!(employee_token: "x")
    @member.time_regs.create!(assigned_task: assigned_task(:task_1), minutes: 30, date_worked: @last + 1)
  end

  def lock_for(user, period = @last, locked_by: @admin)
    TimeLock.create!(organization: @organization, user: user, locked_by: locked_by, period: period)
  end

  test "a member locks last month for themselves" do
    sign_in @member
    assert_difference -> { TimeLock.count }, 1 do
      post :create, params: { month: @month }
    end
    lock = TimeLock.last
    assert_equal [ @member, @member, @last, @organization ], [ lock.user, lock.locked_by, lock.period, lock.organization ]
    assert_redirected_to root_path
  end

  test "a member cannot lock for another user" do
    sign_in @member
    assert_no_difference -> { TimeLock.count } do
      post :create, params: { month: @month, user_id: users(:joe).id }
    end
    assert_redirected_to root_path
  end

  test "an admin locks for another member" do
    sign_in @admin
    assert_difference -> { TimeLock.count }, 1 do
      post :create, params: { month: @month, user_id: @member.id }
    end
    lock = TimeLock.last
    assert_equal [ @member, @admin ], [ lock.user, lock.locked_by ]
  end

  test "an admin locks for an archived member" do
    @member.all_access_infos.find_by(organization: @organization).update_columns(archived_at: Time.current)
    sign_in @admin
    assert_difference -> { TimeLock.count }, 1 do
      post :create, params: { month: @month, user_id: @member.id }
    end
  end

  test "an admin cannot lock for a user outside the organization" do
    sign_in @admin
    assert_no_difference -> { TimeLock.count } do
      post :create, params: { month: @month, user_id: users(:customer_member).id }
    end
    assert_redirected_to root_path
  end

  test "a member cannot lock in an organization without an integration" do
    @organization.tripletex_integration.destroy!
    sign_in @member
    assert_no_difference -> { TimeLock.count } do
      post :create, params: { month: @month }
    end
    assert_redirected_to root_path
  end

  test "an admin cannot lock for a member in an organization without an integration" do
    @organization.tripletex_integration.destroy!
    sign_in @admin
    assert_no_difference -> { TimeLock.count } do
      post :create, params: { month: @month, user_id: @member.id }
    end
    assert_redirected_to root_path
  end

  test "a spectator cannot lock" do
    sign_in users(:organization_spectator)
    assert_no_difference -> { TimeLock.count } do
      post :create, params: { month: @month }
    end
    assert_response :redirect
  end

  test "nobody can lock the current month" do
    sign_in @admin
    assert_no_difference -> { TimeLock.count } do
      post :create, params: { month: Date.current.strftime("%Y-%m"), user_id: @member.id }
    end
    assert flash[:alert].present?
  end

  test "nobody can lock a month from before the connection" do
    old = @last - 2.months
    @member.time_regs.create!(assigned_task: assigned_task(:task_1), minutes: 30, date_worked: old + 1)

    [ @member, @admin ].each do |user|
      sign_in user
      assert_no_difference -> { TimeLock.count } do
        post :create, params: { month: old.strftime("%Y-%m"), user_id: @member.id }
      end
      assert_includes flash[:alert], I18n.t("tripletex.locks.errors.before_connection", month: I18n.l(@last, format: "%B %Y"))
    end
  end

  test "an invalid month is rejected" do
    sign_in @member
    assert_no_difference -> { TimeLock.count } do
      post :create, params: { month: "nonsense" }
    end
    assert flash[:alert].present?
  end

  test "a member cannot unlock" do
    lock = lock_for(@member, locked_by: @member)
    sign_in @member
    assert_no_difference -> { TimeLock.count } do
      delete :destroy, params: { id: lock.id }
    end
    assert_redirected_to root_path
  end

  test "an admin unlocks" do
    lock = lock_for(@member)
    sign_in @admin
    assert_difference -> { TimeLock.count }, -1 do
      delete :destroy, params: { id: lock.id }
    end
    assert flash[:notice].present?
  end

  test "an admin cannot unlock a month with a payout of any status" do
    lock = lock_for(@member)
    sign_in @admin
    %i[pending unclear sent].each do |status|
      PayrollPayout.delete_all
      PayrollPayout.create!(organization: @organization, user: @member, period: @last, status: status, minutes: 60, hours: 1,
                            hourly_wage: 250, amount: 250, tripletex_employee_id: 7, sent_by: @admin)
      assert_no_difference -> { TimeLock.count } do
        delete :destroy, params: { id: lock.id }
      end
      assert_equal I18n.t("tripletex.locks.errors.already_sent"), flash[:alert]
    end
  end

  test "an admin of another organization cannot unlock" do
    lock = lock_for(@member)
    sign_in users(:customer_admin)
    assert_no_difference -> { TimeLock.count } do
      delete :destroy, params: { id: lock.id }
    end
    assert_redirected_to root_path
  end

  class NextLockablePeriod < ActiveSupport::TestCase
    setup do
      @organization = organizations(:organization_one)
      @user = users(:organization_user)
      @task = assigned_task(:task_1)
      @last = Date.current.last_month.beginning_of_month
    end

    def log(date)
      TimeReg.create!(user: @user, assigned_task: @task, minutes: 60, date_worked: date)
    end

    def connect(at)
      TripletexIntegration.create!(organization: @organization, employee_token: "t", connected_at: at)
    end

    test "is nil without an integration" do
      log(@last + 1)
      assert_nil TimeLock.next_lockable_period(user: @user, organization: @organization)
    end

    test "returns the older month when two qualify" do
      connect(Time.current - 6.months)
      log(@last + 1)
      log(@last.last_month + 1)
      assert_equal @last.last_month, TimeLock.next_lockable_period(user: @user, organization: @organization)
    end

    test "skips locked months" do
      connect(Time.current - 6.months)
      log(@last + 1)
      log(@last.last_month + 1)
      TimeLock.create!(organization: @organization, user: @user, locked_by: users(:organization_admin), period: @last.last_month)
      assert_equal @last, TimeLock.next_lockable_period(user: @user, organization: @organization)
    end

    test "skips months before the cutoff" do
      connect(Time.current)
      log(@last.last_month + 1)
      assert_nil TimeLock.next_lockable_period(user: @user, organization: @organization)
      log(@last + 1)
      assert_equal @last, TimeLock.next_lockable_period(user: @user, organization: @organization)
    end

    test "skips a month with only empty entries" do
      connect(Time.current - 6.months)
      TimeReg.create!(user: @user, assigned_task: @task, minutes: 0, date_worked: @last.last_month + 1)
      assert_nil TimeLock.next_lockable_period(user: @user, organization: @organization)
      log(@last + 1)
      assert_equal @last, TimeLock.next_lockable_period(user: @user, organization: @organization)
    end

    test "ignores the current month and discarded entries" do
      connect(Time.current - 6.months)
      log(Date.current.beginning_of_month)
      log(@last + 1).discard!
      assert_nil TimeLock.next_lockable_period(user: @user, organization: @organization)
    end

    test "counts hours on soft-deleted projects" do
      connect(Time.current - 6.months)
      log(@last + 1)
      @task.project.discard
      assert_equal @last, TimeLock.next_lockable_period(user: @user, organization: @organization)
      assert_equal 60, TimeLock.minutes_in(user: @user, organization: @organization, period: @last)
    end
  end
end
