class Client < ApplicationRecord
  validates :name, format: { without: /\r|\n/, message: "Line breaks are not allowed" }
  validates :name, presence: true, length: { minimum: 2, maximum: 30 }, uniqueness: true
  validates :description, presence: true, length: { minimum: 2, maximum: 100 }

  has_many :projects
end
