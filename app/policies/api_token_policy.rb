# API tokens are personal: they belong to a user, not to an organization, and
# nobody else gets to see or manage them.
class ApiTokenPolicy < ApplicationPolicy
  def create?
    true
  end

  def update?
    record.user_id == user.id
  end

  def destroy?
    record.user_id == user.id
  end

  scope_for :relation do |relation|
    relation.where(user_id: user.id)
  end
end
