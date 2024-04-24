class OrganizationPolicy < ApplicationPolicy
  def set_current_organization?
    user.organizations.where(id: record).any?
  end
end
