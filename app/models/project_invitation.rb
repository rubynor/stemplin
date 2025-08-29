class ProjectInvitation < ApplicationRecord
  belongs_to :project
  belongs_to :invited_by, class_name: "User"
  belongs_to :accepted_as_access_info, class_name: "AccessInfo", optional: true

  validates :invited_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :invitation_token, presence: true, uniqueness: true
  validates :invited_email, uniqueness: { scope: :project_id, message: "has already been invited to this project" }
  validates :invited_at, presence: true

  validate :cannot_invite_same_organization_user
  validate :only_one_status_at_a_time

  scope :pending, -> { where(accepted_at: nil, rejected_at: nil) }
  scope :accepted, -> { where.not(accepted_at: nil) }
  scope :rejected, -> { where.not(rejected_at: nil) }
  scope :expired, -> { where("expires_at < ?", Time.current) }
  scope :active, -> { pending.where("expires_at > ?", Time.current) }

  before_validation :set_expires_at, on: :create
  before_validation :generate_invitation_token, on: :create

  def pending?
    accepted_at.nil? && rejected_at.nil? && !expired?
  end

  def accepted?
    accepted_at.present?
  end

  def rejected?
    rejected_at.present?
  end

  def expired?
    expires_at && expires_at < Time.current
  end

  def can_be_accepted?
    pending? && !expired?
  end

  def accept!(organization)
    raise "Cannot accept expired or already processed invitation" unless can_be_accepted?

    transaction do
      # Find or create user
      user = User.find_by(email: invited_email)

      if user.nil?
        user = User.create!(
          email: invited_email,
          first_name: "External",
          last_name: "User",
          password: SecureRandom.hex(16),
          locale: I18n.default_locale.to_s
        )
      end

      # Find or create access_info for the user in the selected organization
      access_info = user.access_infos.find_or_create_by(organization: organization) do |ai|
        ai.role = :organization_user
      end

      # Create the project access
      project_access = ProjectAccess.create!(
        project: project,
        access_info: access_info
      )

      # Mark invitation as accepted
      update!(
        accepted_at: Time.current,
        accepted_as_access_info: access_info
      )

      project_access
    end
  end

  def reject!
    raise "Cannot reject expired or already processed invitation" unless can_be_accepted?

    update!(rejected_at: Time.current)
  end

  def invited_user
    @invited_user ||= User.find_by(email: invited_email)
  end

  def invited_user_organizations
    return Organization.none unless invited_user
    invited_user.organizations
  end

  private

  def set_expires_at
    self.expires_at ||= 7.days.from_now
  end

  def generate_invitation_token
    self.invitation_token ||= SecureRandom.urlsafe_base64(32)
  end

  def cannot_invite_same_organization_user
    return unless invited_user&.organizations&.include?(project.organization)

    errors.add(:invited_email, "cannot invite users from the same organization")
  end

  def only_one_status_at_a_time
    status_count = [ accepted_at, rejected_at ].compact.count
    if status_count > 1
      errors.add(:base, "invitation cannot be both accepted and rejected")
    end
  end
end
