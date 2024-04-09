class UserPolicy < ApplicationPolicy
  scope_for :relation do |relation|
    next relation if user.admin?
    relation.where(id: user)
  end
end
