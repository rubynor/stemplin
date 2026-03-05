class ListTasksTool < ApplicationTool
  description "List all tasks in the organization"

  arguments do
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(organization_id: nil)
    resolve_organization(organization_id)
    authorize! with: TaskPolicy, to: :index?

    tasks = authorized_scope(Task, type: :relation, with: TaskPolicy).order(:name)
    JSON.generate(tasks.map { |task|
      {
        id: task.id,
        name: task.name,
        organization_id: task.organization_id,
        created_at: task.created_at,
        updated_at: task.updated_at
      }
    })
  rescue => e
    format_error(e)
  end
end
