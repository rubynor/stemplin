class MembershipPolicy < ApplicationPolicy
  [ :new?, :create?, :destroy? ].each do |action|
    define_method(action) { user.admin? }
  end

  scope_for :relation do |relation|
    next relation if user.admin?
    relation.where(user: user)
  end
end
