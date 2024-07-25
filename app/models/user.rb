class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  self.ignored_columns += [ "is_verified" ]

  has_many :time_regs
  has_many :access_infos
  has_many :organizations, through: :access_infos
  has_many :clients, through: :organizations
  has_many :projects, through: :clients
  has_many :project_accesses, through: :access_infos

  scope :ordered_by_name, -> { order(:first_name, :last_name) }
  scope :ordered_by_role, -> { joins(:access_infos).select("users.*, access_infos.role").order("access_infos.role ASC") }
  scope :project_restricted, ->(organization) { joins(:access_infos).where(access_infos: { organization: organization, role: AccessInfo.project_restricted_roles }) }

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

  def current_organization
    access_info&.organization
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

  def update_or_create_access_info(role, organization)
    access_info = self.access_info(organization)
    if access_info
      access_info.update!(role: AccessInfo.roles[role])
    else
      access_info = access_infos.create!(organization: organization, role: AccessInfo.roles[role])
    end
    access_info
  end

  def is_super_admin?
    return true if Rails.env.development? # We do not yet have a `super_admin` functionality so let's at least have this in development for now
    access_info.super_admin?
  end
end
