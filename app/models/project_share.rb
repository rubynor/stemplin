class ProjectShare < ApplicationRecord
  EXPIRES_IN = 7.days

  belongs_to :project
  belongs_to :organization, optional: true
  belongs_to :invited_by, class_name: "User"

  enum :status, { pending: 0, accepted: 1, rejected: 2, revoked: 3 }

  has_secure_token :invitation_token

  normalizes :invited_email, with: ->(email) { email.strip.downcase }

  validates :invited_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :invited_email, uniqueness: { scope: :project_id, conditions: -> { pending } }, if: :pending?
  validates :organization, presence: true, if: :accepted?
  validates :organization_id, uniqueness: { scope: :project_id, conditions: -> { accepted } }, if: :accepted?
  validate :organization_is_not_the_owner
  validate :invitee_has_somewhere_else_to_put_it, on: :create

  before_validation :set_expires_at, on: :create

  scope :open_invitations, -> { pending.where("project_shares.expires_at > ?", Time.current) }
  scope :listed, -> { accepted.or(open_invitations) }

  def expired?
    pending? && expires_at <= Time.current
  end

  def acceptable?
    pending? && !expired?
  end

  def accept!(organization)
    raise ArgumentError, "Invitation can no longer be accepted" unless acceptable?

    update!(status: :accepted, organization: organization, accepted_at: Time.current)
  end

  def reject!
    raise ArgumentError, "Invitation can no longer be rejected" unless acceptable?

    update!(status: :rejected, rejected_at: Time.current)
  end

  def revoke!
    raise ArgumentError, "Only pending or accepted shares can be revoked" unless pending? || accepted?

    update!(status: :revoked, revoked_at: Time.current)
  end

  private

  def set_expires_at
    self.expires_at ||= EXPIRES_IN.from_now
  end

  # Someone who only belongs to the owning organization could never accept.
  def invitee_has_somewhere_else_to_put_it
    return unless project

    invitee = User.find_by(email: invited_email)
    return unless invitee

    errors.add(:invited_email, :only_in_owner) if invitee.organizations.to_a == [ project.organization ]
  end

  def organization_is_not_the_owner
    return unless organization && project

    errors.add(:organization, :is_owner) if organization == project.organization
  end
end
