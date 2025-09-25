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
      hp = @pet.hp
      if hp.between?(80, 100)
        paths = [view_context.asset_path("baby_sloth/eating.mp4"), view_context.asset_path("baby_sloth/happy.mp4")]
        render turbo_stream: turbo_stream.change_video("video", paths: paths )
      elsif hp.between?(40, 80)
        paths = [view_context.asset_path("baby_sloth/eating.mp4"), view_context.asset_path("baby_sloth/bored.mp4")]
        render turbo_stream: turbo_stream.change_video("video", paths: paths )
      elsif hp.between?(20, 40)
        paths = [view_context.asset_path("baby_sloth/eating.mp4"), view_context.asset_path("baby_sloth/sad.mp4")]
        render turbo_stream: turbo_stream.change_video("video", paths: paths )
      elsif hp.between?(0, 20)
        paths = [view_context.asset_path("baby_sloth/eating.mp4"), view_context.asset_path("baby_sloth/crying.mp4")]
        render turbo_stream: turbo_stream.change_video("video", paths: paths )
      end
    end
  end

  def implicit_authorization_target
    Pet
  end
end
