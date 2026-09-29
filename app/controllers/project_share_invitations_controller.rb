class ProjectShareInvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_share

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path, alert: t("project_shares.alert.invitation_not_found")
  end

  def show
    authorize! @share, with: ProjectShareInvitationPolicy
    @organizations = eligible_organizations
    @admin_elsewhere = current_user.access_infos.organization_admin.exists?
  end

  def accept
    authorize! @share, with: ProjectShareInvitationPolicy
    organization = eligible_organizations.find { |candidate| candidate.id == params[:organization_id].to_i }
    return redirect_to(project_share_invitation_path(@share.invitation_token), alert: t("project_shares.alert.pick_organization")) unless organization

    ActiveRecord::Base.transaction do
      @share.accept!(organization)
      current_user.activate_organization!(organization)
    end
    redirect_to shared_project_path(@share.project), notice: t("project_shares.notice.accepted", project: @share.project.name)
  end

  def reject
    authorize! @share, with: ProjectShareInvitationPolicy
    @share.reject!
    redirect_to root_path, notice: t("project_shares.notice.rejected", project: @share.project.name)
  end

  private

  def set_share
    @share = authorized_scope(ProjectShare, type: :relation, with: ProjectShareInvitationPolicy).find_by!(invitation_token: params[:token])
  end

  def eligible_organizations
    project = @share.project
    current_user.access_infos.organization_admin.includes(:organization).map(&:organization)
      .reject { |organization| organization == project.organization || Project.shared_with(organization).exists?(project.id) }
      .sort_by(&:name)
  end
end
