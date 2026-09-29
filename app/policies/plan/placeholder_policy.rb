module Plan
  class PlaceholderPolicy < ApplicationPolicy
    def create?
      user.organization_admin? && record.organization == user.current_organization
    end

    alias_method :update?, :create?
    alias_method :destroy?, :create?

    # Placeholders are a planning tool for admins; others only see the ones that
    # hold an assignment they are allowed to see.
    scope_for :relation do |relation|
      relation = relation.where(organization: user.current_organization)
      next relation if user.organization_admin?

      visible = authorized_scope(Plan::Assignment.all, type: :relation)
      relation.where(id: visible.select(:placeholder_id))
    end
  end
end
