# Foreign keys in project params are resolved through authorized scopes, so an
# id from another organization can never be attached to a project.
module ScopedProjectParams
  extend ActiveSupport::Concern

  private

  def scope_project_params(permitted)
    authorized_scope(Client, type: :relation).find(permitted[:client_id]) if permitted[:client_id].present?

    assigned_tasks_attributes(permitted).each do |attributes|
      authorized_scope(Task, type: :relation).find(attributes[:task_id]) if attributes[:task_id].present?
      # A task created along with the project always belongs to the current organization.
      attributes[:task_attributes][:organization_id] = current_user.current_organization.id if attributes[:task_attributes]
    end

    permitted
  end

  # Nested attributes arrive either as a list or as a hash keyed by index.
  def assigned_tasks_attributes(permitted)
    nested = permitted[:assigned_tasks_attributes]
    return [] if nested.blank?

    nested.is_a?(Array) ? nested : nested.values
  end
end
