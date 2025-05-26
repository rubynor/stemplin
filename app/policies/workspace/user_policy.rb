module Workspace
  class UserPolicy < WorkspacePolicy
    %i[ index invite_users create update edit_modal ].each do |action|
      define_method("#{action}?") { user.organization_admin? }
    end

    scope_for :relation do |relation|
      if user.organization_admin?
        relation.joins(:organizations).where(organizations: { id: user.current_organization.id }).distinct
      else
        relation.none
      end
    end
  end
end
