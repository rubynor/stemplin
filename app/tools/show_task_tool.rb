class ShowTaskTool < ApplicationTool
  description "Show details of a specific task"

  arguments do
    required(:id).filled(:integer).description("Task ID")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(id:, organization_id: nil)
    resolve_organization(organization_id)

    task = authorized_scope(Task, type: :relation, with: TaskPolicy).find(id)
    authorize! task, with: TaskPolicy, to: :show?

    JSON.generate({
      id: task.id,
      name: task.name,
      organization_id: task.organization_id,
      created_at: task.created_at,
      updated_at: task.updated_at
    })
  rescue => e
    format_error(e)
  end
end
