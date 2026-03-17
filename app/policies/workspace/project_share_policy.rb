module Workspace
  class ProjectSharePolicy < WorkspacePolicy
    def show?
      user.organization_admin? && owner_or_guest_admin?
    end

    def update?
      user.organization_admin? && guest_org_admin?
    end

    def destroy?
      user.organization_admin? && owner_or_guest_admin?
    end

    scope_for :relation do |relation|
      if user.organization_admin?
        relation
          .where(organization: user.current_organization)
          .or(
            relation.where(
              project: Project.joins(client: :organization)
                .where(organizations: { id: user.current_organization.id })
            )
          )
      else
        relation.none
      end
    end

    private

    # User is admin of the organization that owns the project
    def owner_org_admin?
      record.project.organization == user.current_organization
    end

    # User is admin of the guest organization
    def guest_org_admin?
      record.organization == user.current_organization
    end

    # User is admin of either the owning or guest organization
    def owner_or_guest_admin?
      owner_org_admin? || guest_org_admin?
    end
  end
end
