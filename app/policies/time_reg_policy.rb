class TimeRegPolicy < ApplicationPolicy
  [ :edit?, :update?, :destroy?, :toggle_active?, :export?, :delete_confirmation? ].each do |action|
    define_method(action) do
      user == record.user
    end
  end

  def new_modal?
    true
  end

  def edit_modal?
    true
  end

  def create?
    user == record.user && user.current_organization == record.organization
  end

  scope_for :relation do |relation|
    organization = user.current_organization
    if user.organization_admin?
      relation.joins(:organization).where(organizations: organization).distinct
    else
      relation.joins(:organization, :users).where(organizations: organization, users: user).distinct
    end
  end

  scope_for :relation, :own do |relation|
    organization = user.current_organization
    relation.joins(:organization, :user).where(organizations: organization, users: user).distinct
  end
end
