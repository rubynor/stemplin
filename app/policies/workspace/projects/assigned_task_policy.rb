module Workspace
  module Projects
    class AssignedTaskPolicy < Workspace::ProjectPolicy
      %i[ edit_modal update ].each do |action|
        define_method("#{action}?") { user.organization_admin? && user.current_organization == record.organization }
      end

      # TODO: Deletefile?

      def new_modal?
        user.organization_admin?
      end

      def create?
        user.organization_admin?
      end

      def destroy?
        user.organization_admin?
      end

      def remove?
        user.organization_admin?
      end

      scope_for :relation do |relation|
        organization = user.current_organization
        if user.organization_admin?
          relation.joins(:task).where(tasks: { organization: organization }).distinct
        else
          relation.none
        end
      end
    end
  end
end
