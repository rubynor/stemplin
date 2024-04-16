module Workspace
  class ProjectPolicy < WorkspacePolicy
    [ :import_modal, :add_member_modal ].each do |action|
      define_method("#{action}?") do
        user.admin?
      end
    end

    scope_for :relation do |relation|
      relation.joins(:memberships).where(memberships: { user: user })
    end
  end
end
