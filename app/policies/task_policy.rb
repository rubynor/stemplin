class TaskPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.organization == user.current_organization
  end

  scope_for :relation, :own do |relation|
    users_projects = authorized_scope(Project.all, type: :relation).all
    relation.joins(:projects).where(projects: users_projects).distinct
  end

  scope_for :relation do |relation|
    if user.organization_admin?
      own_ids = relation.where(organization: user.current_organization).select(:id)
      shared_project_ids = ProjectShare.where(organization_id: user.current_organization.id).select(:project_id)
      shared_ids = relation.joins(:assigned_tasks).where(assigned_tasks: { project_id: shared_project_ids }).select(:id)
      relation.where(id: own_ids).or(relation.where(id: shared_ids)).distinct
    elsif user.access_info.organization_spectator?
      projects = authorized_scope(Project.all, type: :relation).all
      relation.joins(:projects).where(projects: projects).distinct
    else
      own_ids = relation.joins(:users).where(organization: user.current_organization, users: { id: user.id }).select(:id)
      user_shared_project_ids = ProjectAccess.joins(:access_info)
                                             .where(access_infos: { user_id: user.id, organization_id: user.current_organization.id })
                                             .joins(:project)
                                             .merge(Project.joins(:project_shares).where(project_shares: { organization_id: user.current_organization.id }))
                                             .select(:project_id)
      shared_ids = relation.joins(:assigned_tasks).where(assigned_tasks: { project_id: user_shared_project_ids }).select(:id)
      relation.where(id: own_ids).or(relation.where(id: shared_ids)).distinct
    end
  end
end
