module Plan
  # A "person" on the plan is a member's AccessInfo: it carries their weekly
  # capacity and working days for the organization.
  class PersonPolicy < ApplicationPolicy
    def update?
      user.organization_admin? && record.organization == user.current_organization
    end

    # Admins plan for the whole team; everyone else sees themselves and the
    # people who share an assignment-visible project with them.
    scope_for :relation do |relation|
      organization = user.current_organization
      relation = relation.where(organization: organization)
      next relation if user.organization_admin?

      visible = authorized_scope(Plan::Assignment.all, type: :relation)
      relation.where(user_id: visible.select(:user_id)).or(relation.where(user_id: user.id))
    end
  end
end
