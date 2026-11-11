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

  def self.for_period(date)
    where(period: date.to_date.beginning_of_month)
  end

  def self.locked?(organization_id:, user_id:, date:)
    return false if organization_id.nil? || user_id.nil? || date.nil?

    where(organization_id: organization_id, user_id: user_id).for_period(date).exists?
  end

  # The oldest ended month with hours and no lock, from the month before the
  # integration was connected onwards. Nil when there is nothing to lock.
  def self.next_lockable_period(user:, organization:)
    integration = organization.tripletex_integration
    return unless integration

    first_month = connected_on(integration).last_month.beginning_of_month
    locked = where(organization_id: organization.id, user_id: user.id).pluck(:period)
    months = kept_time_regs(user_id: user.id, organization_id: organization.id)
             .where(date_worked: first_month...Date.current.beginning_of_month)
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

  # Stands in for a connected_at column.
  def self.connected_on(integration)
    integration.created_at.to_date
  end
  private_class_method :connected_on

  def locked_by_other?
    locked_by_id != user_id
  end

  # True once a payout exists for this lock; a later task implements it.
  def sent?
    false
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

  def no_running_timer
    return if period.blank? || user_id.blank? || organization_id.blank?

    running = TimeReg.all_active
                     .where(user_id: user_id, date_worked: period.beginning_of_month..period.end_of_month)
                     .in_organization(organization_id)
    errors.add(:base, I18n.t("tripletex.locks.errors.timer_running")) if running.exists?
  end
end
