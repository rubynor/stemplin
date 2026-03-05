class ShowProjectTool < ApplicationTool
  description "Show details of a specific project including assigned tasks"

  arguments do
    required(:id).filled(:integer).description("Project ID")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(id:, organization_id: nil)
    resolve_organization(organization_id)

    project = authorized_scope(Project, type: :relation, with: ProjectPolicy).find(id)
    authorize! project, with: ProjectPolicy, to: :show?

    assigned_tasks = project.active_assigned_tasks.includes(:task)

    JSON.generate({
      id: project.id,
      name: project.name,
      description: project.description,
      billable: project.billable,
      rate: project.rate,
      rate_currency: project.rate_currency,
      client_id: project.client_id,
      client_name: project.client.name,
      created_at: project.created_at,
      updated_at: project.updated_at,
      assigned_tasks: assigned_tasks.map { |at|
        {
          id: at.id,
          task_id: at.task_id,
          task_name: at.task.name,
          rate: at.rate,
          rate_currency: at.rate_currency
        }
      }
    })
  rescue => e
    format_error(e)
  end
end
