module Shared
  class TimeRegPolicy < ApplicationPolicy
    scope_for :relation do |relation|
      if user.organization_admin?
        shared_projects = Project.shared_with(user.current_organization)
        relation.where(assigned_task: AssignedTask.where(project_id: shared_projects.select(:id)))
      else
        relation.none
      end
    end
  end
end
