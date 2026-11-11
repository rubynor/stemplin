module Workspace
  class PayrollPayoutPolicy < WorkspacePolicy
    %i[ create mark_sent release ].each do |action|
      define_method("#{action}?") do
        organization = user.current_organization
        user.organization_admin? && organization&.tripletex_integration.present? && record.organization_id == organization.id
      end
    end

    scope_for :relation do |relation|
      organization = user.current_organization
      if user.organization_admin? && organization&.tripletex_integration
        relation.where(organization_id: organization.id)
      else
        relation.none
      end
    end
  end
end
