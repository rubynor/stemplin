module Workspace
  class ProjectPolicy < WorkspacePolicy
    %i[ new index import_modal ].each do |action|
      define_method("#{action}?") { user.organization_admin? }
    end

    %i[ create edit update destroy ].each do |action|
      define_method("#{action}?") do
        user.organization_admin? && record.organization == user.current_organization
      end
    end

    def show?
      return true if user.organization_admin? && record.organization == user.current_organization
      return true if user.organization_admin? && record.shared_with?(user.current_organization)
      false
    end

    scope_for :relation do |relation|
      organization = user.current_organization

      own_ids = relation.joins(client: :organization)
                        .where(organizations: { id: organization.id })
                        .select(:id)
      shared_ids = relation.joins(:project_shares)
                           .where(project_shares: { organization_id: organization.id })
                           .select(:id)
      combined = relation.where(id: own_ids).or(relation.where(id: shared_ids))

      unless user.organization_admin?
        combined = combined.where(
          id: ProjectAccess.where(access_info: user.access_info(organization))
                           .select(:project_id)
        )
      end

      combined.distinct
    end
  end
end
