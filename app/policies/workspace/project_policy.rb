module Workspace
  class ProjectPolicy < WorkspacePolicy
    %i[ new index import_modal ].each do |action|
      define_method("#{action}?") { user.organization_admin? }
    end

    %i[ create show edit update destroy ].each do |action|
      define_method("#{action}?") do
        user.organization_admin? && record.organization == user.current_organization
      end
    end

    scope_for :relation do |relation|
      if user.organization_admin?
        relation.joins(:organization).where(organizations: { id: user.current_organization.id }).distinct
      else
        relation.none
      end
    end
  end
end
