class UpdateProjectTool < ApplicationTool
  description "Update an existing project"

  arguments do
    required(:id).filled(:integer).description("Project ID")
    optional(:name).filled(:string).description("Project name (2-60 characters)")
    optional(:description).filled(:string).description("Project description")
    optional(:billable).filled(:bool).description("Whether the project is billable")
    optional(:rate_currency).filled(:string).description("Hourly rate in currency format (e.g. '1,25' for 1.25)")
    optional(:client_id).filled(:integer).description("Client ID to associate with")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(id:, name: nil, description: nil, billable: nil, rate_currency: nil, client_id: nil, organization_id: nil)
    resolve_organization(organization_id)

    project = authorized_scope(Project, type: :relation, with: ProjectPolicy).find(id)
    authorize! project, with: ProjectPolicy, to: :update?

    attrs = {}
    attrs[:name] = name if name
    attrs[:description] = description if description
    attrs[:billable] = billable unless billable.nil?
    attrs[:client_id] = client_id if client_id
    project.rate_currency = rate_currency if rate_currency
    project.update!(attrs)

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
