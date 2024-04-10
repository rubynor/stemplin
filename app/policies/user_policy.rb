class UserPolicy < ApplicationPolicy
  scope_for :relation do |relation|
    organization = user.organization
    if user.admin?
      relation.where(organization: organization)
    else
      relation.where(organization: organization, id: user)
    end
  end
end
