class PetController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize!
  end

  def implicit_authorization_target
    :pet
  end
end
