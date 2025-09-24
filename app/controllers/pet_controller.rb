class PetController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize!
    @pet = current_user.pets.order(created_at: :asc).first
  end

  def feed_pet
    authorize!
    if turbo_frame_request?
      @pet = current_user.pets.order(created_at: :asc).first
      ActiveRecord::Base.transaction do
        return if @pet.food_stock <= 0
        @pet.food_stock = [@pet.food_stock - 1, 0].max
        @pet.hp = [@pet.hp + 10, 100].min
        @pet.save!
      end
      render partial: "pet"
    end
  end

  def implicit_authorization_target
    Pet
  end
end
