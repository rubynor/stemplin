module Workspace
  class ProjectAccessPolicy < WorkspacePolicy
    scope_for :relation do |relation|
      if user.organization_admin?
        relation.joins(access_info: :organization).where(access_infos: { organization_id: user.current_organization.id }).distinct
      else
        relation.none
      end
    end
  end
end
