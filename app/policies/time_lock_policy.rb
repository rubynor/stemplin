class TimeLockPolicy < ApplicationPolicy
  def create?
    return false unless same_organization?
    return true if user.organization_admin?

    record.user_id == user.id && !user.access_info.organization_spectator?
  end

  def destroy?
    same_organization? && user.organization_admin?
  end

  scope_for :relation do |relation|
    organization = user.current_organization
    next relation.none unless organization

    scoped = relation.where(organization_id: organization.id)
    user.organization_admin? ? scoped : scoped.where(user_id: user.id)
  end

  private

  def same_organization?
    record.organization_id.present? && record.organization_id == user.current_organization&.id
  end
end
