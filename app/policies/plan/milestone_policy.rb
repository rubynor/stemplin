module Plan
  class MilestonePolicy < ApplicationPolicy
    def create?
      user.organization_admin? && record.organization == user.current_organization
    end

    alias_method :update?, :create?
    alias_method :destroy?, :create?

    scope_for :relation do |relation|
      projects = authorized_scope(Project.all, type: :relation)
      relation.where(organization: user.current_organization, project_id: projects.select(:id))
    end
  end
end
