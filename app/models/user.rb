class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :memberships
  has_many :projects, through: :memberships
  has_many :time_regs, through: :memberships
  has_many :tasks, through: :time_regs
  has_many :clients, through: :projects

  validates :key, inclusion: { in: [ ENV["AUTENTICATION_KEY"] ], message: "is Invalid" }

  enum :role, %i[ user admin ]

  def organization_clients
    clients.distinct
  end


  def name
    "#{first_name} #{last_name}"
  end
end
