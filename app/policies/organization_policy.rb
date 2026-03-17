class OrganizationPolicy < ApplicationPolicy
  def index? = true
  def show? = user.organizations.where(id: record).any?

  def set_current_organization?
    user.organizations.where(id: record).any?
  end
end
