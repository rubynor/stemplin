class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :time_regs
  has_many :access_infos
  has_many :organizations, through: :access_infos

  validates :key, inclusion: { in: [ ENV["AUTENTICATION_KEY"] ], message: "is Invalid" }

  def organization_clients
    clients.distinct
  end

  def name
    "#{first_name} #{last_name}".strip
  end
end
