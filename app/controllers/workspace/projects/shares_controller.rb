module Workspace
  module Projects
    class SharesController < WorkspaceController
      before_action :set_project

      def create
        @share = @project.project_shares.new(invited_email: params.dig(:project_share, :invited_email), invited_by: current_user)
        authorize! @share

        if @share.save
          UserMailer.project_share_invitation_email(project_share: @share).deliver_later
          flash[:success] = t("project_shares.notice.invited", email: @share.invited_email)
        else
          flash[:error] = @share.errors.full_messages.to_sentence
        end
        redirect_to workspace_project_path(@project, tab: "sharing")
      end

      def destroy
        @share = authorized_scope(ProjectShare, type: :relation).where(project: @project).find(params[:id])
        authorize! @share

        @share.revoke!
        flash[:success] = t(@share.accepted_at ? "project_shares.notice.revoked" : "project_shares.notice.cancelled")
        redirect_to workspace_project_path(@project, tab: "sharing")
      end

      private

      def set_project
        @project = authorized_scope(Project, type: :relation).find(params[:project_id])
      end
    end
  end
end
