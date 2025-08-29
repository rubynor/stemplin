module Workspace
  module Projects
    class AssignedTaskPolicy < Workspace::ProjectPolicy
      scope_for :relation do |relation|
        organization = user.current_organization
        if user.organization_admin?
          relation.joins(task: :organization).where(tasks: { organizations: { id: organization.id } }).distinct
        else
          relation.none
        end
      end
    end
  end
end
