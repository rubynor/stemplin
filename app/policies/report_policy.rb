class ReportPolicy < ApplicationPolicy
  %i[ index detailed ].each do |action|
    define_method("#{action}?") { true }
  end

  def send_to_tripletex?
    user.organization_admin? && user.current_organization.tripletex_integration.present?
  end
end
