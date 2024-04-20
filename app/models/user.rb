class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :time_regs
  has_many :access_infos
  has_many :organizations, through: :access_infos

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

  private

  def access_info
    # For simplicity, the current tie to a organization is set to the first
    # TODO: Implement a function that lets a user choose between it's associated organizations
    access_infos.first
  end
end
