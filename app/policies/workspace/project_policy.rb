module Workspace
  class ProjectPolicy < WorkspacePolicy
    [ :import_modal, :add_member_modal ].each do |action|
      define_method("#{action}?") do
        user.organization_admin?
      end
    end

    scope_for :relation do |relation|
      if user.organization_admin?
        relation.joins(:organization).where(organizations: user.current_organization).distinct
      else
        relation.none
      end
    end
  end
end
