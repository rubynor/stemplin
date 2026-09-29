module Plan
  class AssignmentPolicy < ApplicationPolicy
    def create?
      user.organization_admin? && record.organization == user.current_organization
    end

    alias_method :update?, :create?
    alias_method :destroy?, :create?
    alias_method :split?, :create?

    # Admins see the whole organization. Everyone else sees assignments on the
    # projects they have access to, plus their own (which covers their time off).
    scope_for :relation do |relation|
      organization = user.current_organization
      relation = relation.where(organization: organization)
      next relation if user.organization_admin?

      projects = authorized_scope(Project.all, type: :relation)
      relation.where(project_id: projects.select(:id)).or(relation.where(user_id: user.id))
    end
  end
end
