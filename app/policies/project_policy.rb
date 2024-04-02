class ProjectPolicy < ApplicationPolicy
  [ :show?, :new?, :create?, :edit?, :update?, :destroy?, :import? ].each do |action|
    define_method(action) { user.admin? }
  end

  scope_for :relation do |relation|
    next relation if user.admin?
    relation.joins(:users).where(users: user).distinct
  end
end
