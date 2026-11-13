# One month of one member's hours paid through Tripletex. The unique index on organization, user and
# period is what stops a month being paid twice; the row exists from before the first Tripletex call.
#
# pending: being sent right now (or the request died mid-way).
# sent:    the payslip line exists in Tripletex.
# unclear: Stemplin cannot tell whether a payslip exists; an admin checks Tripletex and resolves it.
class PayrollPayout < ApplicationRecord
  # Longer than any send can take (every Tripletex call is bounded by the client's timeouts),
  # so a pending payout older than this belongs to a request that is no longer running.
  IN_FLIGHT_FOR = 5.minutes

  has_paper_trail

  belongs_to :organization
  belongs_to :user
  belongs_to :sent_by, class_name: "User"

  enum :status, { pending: 0, sent: 1, unclear: 2 }

  validates :period, :minutes, :hours, :hourly_wage, :amount, :tripletex_employee_id, presence: true
  validate :period_is_first_of_month

  # The admin found the payslip in Tripletex. sent_by stays the admin who sent it; PaperTrail records who resolved it.
  def mark_sent!(by:)
    resolve! do
      PaperTrail.request(whodunnit: by.id.to_s) { update!(status: :sent, sent_at: Time.current) }
    end
  end

  # The admin found no payslip in Tripletex: the month can be paid again.
  def release!
    resolve! { destroy! }
  end

  private

  # Locks the row so a resolution cannot interleave with the send that is still working on it.
  def resolve!
    with_lock do
      raise Payroll::Error, I18n.t("tripletex.payroll.errors.already_sent") if sent?
      raise Payroll::Error, I18n.t("tripletex.payroll.errors.in_progress") if pending? && created_at > IN_FLIGHT_FOR.ago

      yield
    end
  end

  def period_is_first_of_month
    return if period.blank? || period.day == 1

    errors.add(:period, I18n.t("tripletex.locks.errors.period_not_first_of_month"))
  end
end
