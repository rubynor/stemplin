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

  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }

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

  def access_info
    access_infos.find_by(active: true) || access_infos.first
  end

  def project_restricted?(organization = nil)
    a_i = organization ? access_infos.find_by(organization: organization) : access_info
    a_i.project_restricted?
  end
end
