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

  def set_organization(organization)
    return false unless access_infos.exists?(organization: organization)

    ActiveRecord::Base.transaction do
      begin
        access_info.update(active: false)
        access_infos.find_by(organization: organization).update(active: true)
      rescue ActiveRecord::StatementInvalid
        return false
      end
    end

    true
  end

  private

  def access_info
    if access_infos.exists?(active: true)
      access_infos.find_by(active: true)
    else
      access_info = access_infos.first
      access_info.update(active: true)
      access_info
    end
  end
end
