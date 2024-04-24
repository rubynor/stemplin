module Workspace
  module Projects
    class MembershipsController < ProjectsController
      before_action :set_project, except: %i[delete_confirmation]
      before_action :set_membership, only: %i[delete_confirmation destroy]

      def create
        @user = User.find_by(email: membership_params[:email])

        @membership = Membership.new(project: @project, user: @user)

        if @membership.save
          render turbo_stream: [
            turbo_flash(type: :success, data: "Member added to project."),
            turbo_stream.action(:remove_modal, :modal),
            turbo_stream.append("#{dom_id(@project)}_memberships", partial: "workspace/projects/membership", locals: { membership: @membership })
          ]
        else
          render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/projects/memberships/form", locals: { project: @project, membership: @membership })
        end
      end

      def new_modal
        @membership = Membership.new
      end

      def delete_confirmation
      end

      def destroy
        if @membership.destroy
          render turbo_stream: [
            turbo_flash(type: :success, data: "Member removed from project."),
            turbo_stream.remove(dom_id(@membership)),
            turbo_stream.action(:remove_modal, :modal)
          ]
        else
          render turbo_stream: turbo_flash(type: :error, data: "Unable to proceed, #{@membership.errors.full_messages.join(", ")}.")
        end
      end

      private

      def set_project
        @project = Project.find(params[:project_id])
      end

      def membership_params
        params.require(:membership).permit(:email)
      end

      def set_membership
        @membership = Membership.find(params[:id])
      end
    end
  end
end
