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

  def organization_clients
    clients.distinct
  end

  def name
    "#{first_name} #{last_name}".strip
  end

  def organization_admin?
    access_info.organization_admin?
  end

  def current_organization
    access_info.organization
  end

  def access_info
    access_infos.find_by(active: true) || access_infos.first
  end
end
