module Shared
  # The recipient's side: projects other organizations have shared with the current one. Only admins
  # see them, and only to read — nothing under Shared:: may write to a project it does not own.
  class ProjectPolicy < ApplicationPolicy
    def index?
      user.organization_admin?
    end

    %i[ show export destroy ].each do |action|
      define_method("#{action}?") do
        user.organization_admin? && Project.shared_with(user.current_organization).exists?(record.id)
      end
    end

    scope_for :relation do |relation|
      if user.organization_admin?
        relation.shared_with(user.current_organization)
      else
        relation.none
      end
    end
  end
end
