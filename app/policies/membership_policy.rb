class MembershipPolicy < ApplicationPolicy
  [ :new?, :create?, :destroy? ].each do |action|
    define_method(action) { user.admin? }
  end

  scope_for :relation do |relation|
    organization = user.organization
    if user.admin?
      relation.joins(:organization).where(organization: organization).distinct
    else
      relation.joins(:organization).where(organization: organization, user: user).distinct
    end
  end
end
