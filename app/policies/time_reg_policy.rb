class TimeRegPolicy < ApplicationPolicy
  %i[ show edit edit_modal update destroy toggle_active ].each do |action|
    define_method("#{action}?") do
      is_admin_allowed = user.organization_admin? && record.organization == user.current_organization
      user == record.user || is_admin_allowed
    end
  end

  %i[ index new_modal update_tasks_select export ].each do |action|
    define_method("#{action}?") do
      !user.access_info.organization_spectator?
    end
  end

  def create?
    return false if user.access_info.organization_spectator?

    same_organization = user.current_organization == record.organization
    no_organization = record.organization.nil?

    allowed = if user.organization_admin?
      same_organization
    else
      (same_organization || no_organization) && record.user == user
    end
    allowed && assign?
  end

  # Checked once new attributes are assigned and before they are saved: the
  # other rules only look at what the time reg was, not at what it becomes.
  def assign?
    assignable_task? && assignable_user?
  end

  scope_for :relation do |relation|
    organization = user.current_organization
    if user.organization_admin?
      relation.joins(:organization).where(organizations: { id: organization.id }).distinct
    elsif user.access_info.organization_spectator?
      projects = authorized_scope(Project.all, type: :relation).all
      relation.joins(:project).where(projects: { id: projects }).distinct
    else
      relation.joins(:organization, :user).where(organizations: { id: organization.id }, users: { id: user.id }).distinct
    end
  end

  scope_for :relation, :own do |relation|
    organization = user.current_organization
    relation.joins(:organization, :user).where(organizations: { id: organization.id }, users: { id: user.id }).distinct
  end

  private

  # The task has to sit on a project the user can register time on. A missing
  # task is left to the model's validations.
  def assignable_task?
    return true unless record.assigned_task_id_changed?
    return true if record.assigned_task.nil?

    authorized_scope(Project.all, type: :relation).where(id: record.assigned_task.project_id).exists?
  end

  # Time is registered for oneself; admins may register it for a member of
  # their organization.
  def assignable_user?
    return true unless record.user_id_changed?
    return true if record.user == user

    user.organization_admin? && AccessInfo.unarchived.exists?(organization: user.current_organization, user: record.user)
  end
end
