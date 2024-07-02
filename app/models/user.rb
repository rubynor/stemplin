class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

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
end
