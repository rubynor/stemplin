class DeleteProjectTool < ApplicationTool
  description "Delete a project (soft delete)"

  arguments do
    required(:id).filled(:integer).description("Project ID")
    optional(:organization_id).filled(:integer).description("Organization ID (uses default if not provided)")
  end

  def call(id:, organization_id: nil)
    resolve_organization(organization_id)

    project = authorized_scope(Project, type: :relation, with: ProjectPolicy).find(id)
    authorize! project, with: ProjectPolicy, to: :destroy?
    project.discard!

    JSON.generate({ status: "deleted", id: project.id })
  rescue => e
    format_error(e)
  end
end
