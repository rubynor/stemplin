class Users::InvitationsController < Devise::InvitationsController
  layout "devise"

  def new
    raise ActionController::RoutingError.new("Not Found")
  end

  def create
    raise ActionController::RoutingError.new("Not Found")
  end
end
