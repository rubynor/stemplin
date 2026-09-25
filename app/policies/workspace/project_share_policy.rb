module Workspace
  # The owner's side: an admin shares their organization's projects and revokes those shares.
  class ProjectSharePolicy < WorkspacePolicy
    %i[ create destroy ].each do |action|
      define_method("#{action}?") do
        user.organization_admin? && record.project.organization == user.current_organization
      end
    end

    scope_for :relation do |relation|
      if user.organization_admin?
        relation.where(project: Project.owned_by(user.current_organization))
      else
        relation.none
      end
    end
  end
end
