class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :memberships
  has_many :projects, through: :memberships
  has_many :time_regs, through: :memberships
  has_many :clients, through: :projects

  validates :key, inclusion: { in: [ "Ruby" ], message: "is Invalid" }

  def name
    "#{first_name} #{last_name}"
  end
end
