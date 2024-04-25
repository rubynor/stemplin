module Workspace
  class WorkspacePolicy < ApplicationPolicy
    COMMON_ACTIONS_FOR_ADMIN = %i[index show new create edit update destroy new_modal edit_modal].freeze

    COMMON_ACTIONS_FOR_ADMIN.each do |action|
      define_method("#{action}?") do
        user.organization_admin?
      end
    end
  end
end
