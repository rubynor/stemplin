module Workspace
  class ProjectPolicy < WorkspacePolicy
    %i[ index ].each do |action|
      define_method("#{action}?") { user.organization_admin? }
    end

    %i[ create show edit_modal update new_modal import_modal destroy add_member_modal ].each do |action|
      define_method("#{action}?") do
        user.organization_admin? && record.organization == user.current_organization
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
