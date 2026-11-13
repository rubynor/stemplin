# Freezes one user's time entries for one calendar month in one organization.
# The rule is enforced by TimeReg, so every write path is covered.
class TimeLock < ApplicationRecord
  has_paper_trail

  belongs_to :organization
  belongs_to :user
  belongs_to :locked_by, class_name: "User"

  validates :period, presence: true, uniqueness: { scope: [ :organization_id, :user_id ] }
  validate :period_is_first_of_month
  validate :month_has_ended, on: :create
  validate :no_running_timer, on: :create
  validate :has_hours, on: :create
  validate :not_before_connection, on: :create

  # Paid hours stay locked whichever path tries to unlock them.
  before_destroy { throw :abort if sent? }

  def self.for_period(date)
    where(period: date.to_date.beginning_of_month)
  end

  def self.locked?(organization_id:, user_id:, date:)
    return false if organization_id.nil? || user_id.nil? || date.nil?

    where(organization_id: organization_id, user_id: user_id).for_period(date).exists?
  end

  # The oldest ended month with hours and no lock, from the first lockable month onwards.
  # Nil when there is nothing to lock.
  def self.next_lockable_period(user:, organization:)
    first_month = first_lockable_period(organization)
    return unless first_month

    locked = where(organization_id: organization.id, user_id: user.id).pluck(:period)
    months = kept_time_regs(user_id: user.id, organization_id: organization.id)
             .where(date_worked: first_month...Date.current.beginning_of_month)
             .where(minutes: 1..) # a month of only empty entries has nothing to lock
             .distinct.pluck(Arel.sql("date_trunc('month', time_regs.date_worked)::date"))
    (months - locked).min
  end

  # Minutes logged in the month, including on soft-deleted projects and clients.
  def self.minutes_in(user:, organization:, period:)
    kept_time_regs(user_id: user.id, organization_id: organization.id)
      .where(date_worked: period.beginning_of_month..period.end_of_month)
      .sum(:minutes)
  end

  # Kept time entries of one user in one organization, ignoring soft-deletes on project and client.
  def self.kept_time_regs(user_id:, organization_id:)
    TimeReg.where(user_id: user_id).in_organization(organization_id)
  end
  private_class_method :kept_time_regs

  # The month before the integration was connected: earlier months were paid outside Stemplin.
  # Nil without an integration.
  def self.first_lockable_period(organization)
    organization.tripletex_integration&.connected_at&.to_date&.last_month&.beginning_of_month
  end

  def locked_by_other?
    locked_by_id != user_id
  end

  # True once a payout of any status exists for this month: an unclear or pending payout may have
  # reached Tripletex, so its hours must not change either.
  def sent?
    PayrollPayout.exists?(organization_id: organization_id, user_id: user_id, period: period)
  end

  private

  def period_is_first_of_month
    return if period.blank? || period.day == 1

    errors.add(:period, I18n.t("tripletex.locks.errors.period_not_first_of_month"))
  end

  def month_has_ended
    return if period.blank? || period.end_of_month < Date.current

    errors.add(:period, I18n.t("tripletex.locks.errors.month_not_ended"))
  end

  def has_hours
    return if period.blank? || user.blank? || organization.blank?
    return if TimeLock.minutes_in(user:, organization:, period:).positive?

    errors.add(:base, I18n.t("tripletex.locks.errors.no_hours"))
  end

  # Without an integration there is no cutoff; the policy refuses those locks.
  def not_before_connection
    return if period.blank? || organization.blank?

    first_month = TimeLock.first_lockable_period(organization)
    return if first_month.nil? || period >= first_month

    errors.add(:base, I18n.t("tripletex.locks.errors.before_connection", month: I18n.l(first_month, format: "%B %Y")))
  end

  def no_running_timer
    return if period.blank? || user_id.blank? || organization_id.blank?

    running = TimeReg.all_active
                     .where(user_id: user_id, date_worked: period.beginning_of_month..period.end_of_month)
                     .in_organization(organization_id)
    errors.add(:base, I18n.t("tripletex.locks.errors.timer_running")) if running.exists?
  end
end
