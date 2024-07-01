class TimeRegPolicy < ApplicationPolicy
  %i[ edit update destroy toggle_active export ].each do |action|
    define_method("#{action}?") do
      user == record.user
    end
  end

  %i[ index new_modal edit_modal update_tasks_select ].each do |action|
    define_method("#{action}?") do
      !user.access_info.organization_spectator?
    end
  end

  def create?
    user == record.user && user.current_organization == record.organization
  end

  scope_for :relation do |relation|
    organization = user.current_organization
    if user.organization_admin?
      relation.joins(:organization).where(organizations: organization).distinct
    else
      relation.joins(:organization, :user).where(organizations: organization, users: user).distinct
    end
  end

  scope_for :relation, :own do |relation|
    organization = user.current_organization
    relation.joins(:organization, :user).where(organizations: organization, users: user).distinct
  end
end
