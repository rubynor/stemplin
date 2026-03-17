module Workspace
  class ProjectShareTaskRatePolicy < WorkspacePolicy
    def create?
      user.organization_admin? && guest_org_admin?
    end

    def update?
      user.organization_admin? && guest_org_admin?
    end

    def destroy?
      user.organization_admin? && guest_org_admin?
    end

    scope_for :relation do |relation|
      if user.organization_admin?
        relation.joins(:project_share).where(project_shares: { organization_id: user.current_organization.id })
      else
        relation.none
      end
    end

    private

    # User is admin of the guest organization that owns this task rate
    def guest_org_admin?
      record.project_share.organization == user.current_organization
    end
  end
end
