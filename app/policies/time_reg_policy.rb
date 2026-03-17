class TimeRegPolicy < ApplicationPolicy
  def show?
    is_admin_allowed = user.organization_admin? && record.organization == user.current_organization
    user == record.user || is_admin_allowed || admin_of_shared_project?
  end

  %i[ edit update destroy toggle_active export ].each do |action|
    define_method("#{action}?") do
      is_admin_allowed = user.organization_admin? && record.organization == user.current_organization
      user == record.user || is_admin_allowed
    end
  end

  %i[ index new_modal edit_modal update_tasks_select ].each do |action|
    define_method("#{action}?") do
      !user.access_info.organization_spectator?
    end
  end

  def create?
    return false if user.access_info.organization_spectator?

    same_organization = user.current_organization == record.organization
    no_organization = record.organization.nil?
    shared_project = on_shared_project?

    if user.organization_admin?
      same_organization
    else
      (same_organization || no_organization || shared_project) && record.user == user
    end
  end

  scope_for :relation do |relation|
    organization = user.current_organization
    shared_project_ids = ProjectShare.where(organization_id: organization.id).select(:project_id)

    if user.organization_admin?
      own_ids = relation.joins(:organization).where(organizations: { id: organization.id }).select(:id)
      shared_ids = relation.joins(assigned_task: :project).where(projects: { id: shared_project_ids }).select(:id)
      relation.where(id: own_ids).or(relation.where(id: shared_ids)).distinct
    elsif user.access_info.organization_spectator?
      projects = authorized_scope(Project.all, type: :relation).all
      relation.joins(:project).where(projects: projects).distinct
    else
      relation.where(user: user).distinct
    end
  end

  scope_for :relation, :own do |relation|
    organization = user.current_organization
    relation.joins(:organization, :user).where(organizations: { id: organization.id }, users: { id: user.id }).distinct
  end

  private

  def on_shared_project?
    ProjectShare.exists?(project: record.project, organization: user.current_organization)
  end

  def admin_of_shared_project?
    user.organization_admin? && on_shared_project?
  end
end
