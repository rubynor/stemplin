module Workspace
  class UserPolicy < WorkspacePolicy
    %i[ index invite_users create update edit_modal restore ].each do |action|
      define_method("#{action}?") { user.organization_admin? }
    end

    # Admins can't archive themselves: that would lock them out of the organization.
    def archive?
      user.organization_admin? && record != user
    end

    scope_for :relation do |relation|
      if user.organization_admin?
        relation.joins(:organizations).where(organizations: { id: user.current_organization.id }).distinct
      else
        relation.none
      end
    end

    scope_for :relation, :archived do |relation|
      if user.organization_admin?
        relation.joins(:all_access_infos).merge(AccessInfo.archived).where(access_infos: { organization_id: user.current_organization.id }).distinct
      else
        relation.none
      end
    end
  end
end
