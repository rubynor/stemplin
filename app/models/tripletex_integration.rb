class TripletexIntegration < ApplicationRecord
  belongs_to :organization

  encrypts :employee_token

  validates :employee_token, presence: true

  def api
    Tripletex::Client.new(employee_token: employee_token)
  end
end
