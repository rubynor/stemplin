class ClientPolicy < ApplicationPolicy
  [ :index?, :show?, :new?, :create?, :edit?, :update?, :destroy? ].each do |action|
    define_method(action) { user.admin? }
  end

  scope_for :relation do |relation|
    next relation if user.admin?
    relation.joins(:projects).where(projects: user.projects).distinct
  end
end
