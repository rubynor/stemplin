class TimeRegPolicy < ApplicationPolicy
  [ :index?, :new_modal?, :create?, :edit?, :update?, :destroy?, :toggle_active?, :export?, :update_tasks_select?, :edit_modal? ].each do |action|
    define_method(action) { true }
  end

  scope_for :relation do |relation|
    organization = user.organization
    if user.admin?
      relation.joins(:organization).where(organizations: organization).distinct
    else
      relation.joins(:organization, :user).where(organizations: organization, users: user).distinct
    end
  end

  scope_for :own do |relation|
    organization = user.organization
    relation.joins(:organization, :user).where(organizations: organization, users: user).distinct
  end
end
