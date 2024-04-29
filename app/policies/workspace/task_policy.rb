module Workspace
  class TaskPolicy < WorkspacePolicy
    %i[ edit_modal update destroy delete_confirmation ].each do |action|
      define_method("#{action}?") do
        user.organization_admin? && record.organization == user.current_organization
      end
    end

    scope_for :relation do |relation|
      if user.organization_admin?
        relation.where(organization: user.current_organization)
      else
        relation.none
      end
    end
  end
end
