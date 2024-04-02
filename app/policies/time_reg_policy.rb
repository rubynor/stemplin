class TimeRegPolicy < ApplicationPolicy
  [ :index?, :new_modal?, :create?, :edit?, :update?, :destroy?, :toggle_active?, :export?, :update_tasks_select?, :edit_modal? ].each do |action|
    define_method(action) { true }
  end

  scope_for :relation do |relation|
    next relation if user.admin?
    relation.joins(:user).where(user: user)
  end

  scope_for :own do |relation|
    relation.joins(:user).where(users: user)
  end
end
