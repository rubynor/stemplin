module Workspace
  module Projects
    class TaskPolicy < Workspace::ProjectPolicy
      %i[ new_modal create ].each do |action|
        define_method("#{action}?") { user.organization_admin? && user.current_organization == record.organization }
      end
    end
  end
end
