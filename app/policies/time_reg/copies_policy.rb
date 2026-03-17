# frozen_string_literal: true

class TimeReg::CopiesPolicy < ApplicationPolicy
  def create?
    is_admin_allowed = user.organization_admin? && record.organization == user.current_organization
    user == record.user || is_admin_allowed
  end
end
