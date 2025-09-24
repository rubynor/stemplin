class PetPolicy < ApplicationPolicy
  def index?
    true
  end

  def feed_pet?
    true
  end
end
