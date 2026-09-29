class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  self.ignored_columns += [ "is_verified", "api_token" ]

  has_many :time_regs
  # `access_infos` only covers organizations the user is still a member of, so
  # everything derived from it (organizations, current organization, policy
  # scopes) ignores memberships that were archived when the user left.
  has_many :all_access_infos, class_name: "AccessInfo"
  has_many :access_infos, -> { unarchived }
  has_many :organizations, through: :access_infos
  has_many :clients, through: :organizations
  has_many :projects, through: :clients
  has_many :project_accesses, through: :access_infos
  has_many :plan_assignments, class_name: "Plan::Assignment", dependent: :destroy

  scope :ordered_by_name, -> { order(:first_name, :last_name) }
  scope :ordered_by_role, -> { joins(:access_infos).select("users.*, access_infos.role").order("access_infos.role ASC") }
  scope :project_restricted, ->(organization) { joins(access_infos: :organization).where(access_infos: { organizations: { id: organization.id }, role: AccessInfo.project_restricted_roles }) }
  # TODO: Use invitation_accepted for onboarded scope
  scope :onboarded, -> { where.not(first_name: nil).where.not(last_name: nil) }
  scope :unarchived_in, ->(organization) { where(id: AccessInfo.unarchived.where(organization: organization).select(:user_id)) }

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }
  validates :first_name, :last_name, :email, presence: true

  def organization_clients
    clients.distinct
  end

  def name
    "#{first_name} #{last_name}".strip
  end

  def name_with_role(organization = nil)
    "#{name} (#{I18n.t("access_info.role.#{access_info(organization).role}_short")})"
  end

  def organization_admin?
    access_info&.organization_admin?
  end

  def spectator_in_organization?(organization)
    access_info(organization)&.organization_spectator?
  end

  def current_organization
    access_info&.organization
  end

  def activate_organization!(organization)
    transaction do
      access_info&.update!(active: false)
      access_infos.find_by!(organization: organization).update!(active: true)
    end
  end

  def access_info(organization = nil)
    return access_infos.find_by(organization: organization) if organization
    access_infos.find_by(active: true) || access_infos.first
  end

  def project_restricted?(organization)
    access_infos.find_by(organization: organization).project_restricted?
  end

  def pending_invitation?
    !accepted_or_not_invited?
  end

  # Someone archived in every organization they belonged to has left for good;
  # users without any membership yet are still onboarding and may sign in.
  def active_for_authentication?
    super && !archived_everywhere?
  end

  def inactive_message
    archived_everywhere? ? :archived : super
  end

  def archived_everywhere?
    all_access_infos.exists? && !access_infos.exists?
  end

  # Re-inviting someone whose membership was archived restores it.
  def update_or_create_access_info(role, organization)
    access_info = all_access_infos.find_by(organization: organization)
    if access_info
      access_info.update!(role: AccessInfo.roles[role], archived_at: nil)
    else
      access_info = access_infos.create!(organization: organization, role: AccessInfo.roles[role])
    end
    access_info
  end

  def is_super_admin?
    return true if Rails.env.development? # We do not yet have a `super_admin` functionality so let's at least have this in development for now
    access_info.super_admin?
  end

  def regenerate_api_token!
    token = SecureRandom.base58(24)
    update!(api_token_digest: Digest::SHA256.hexdigest(token))
    token
  end

  def ensure_api_token!
    regenerate_api_token! unless api_token_digest?
  end

  def self.find_by_api_token(token)
    return nil if token.blank?

    find_by(api_token_digest: Digest::SHA256.hexdigest(token))
  end
end
