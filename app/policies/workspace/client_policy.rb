module Workspace
  class ClientPolicy < WorkspacePolicy
    %i[ index ].each do |action|
      define_method("#{action}?") { user.organization_admin? }
    end

    %i[ new_modal create edit_modal update delete_confirmation destroy ].each do |action|
      define_method("#{action}?") { user.organization_admin? && record.organization == user.current_organization }
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
