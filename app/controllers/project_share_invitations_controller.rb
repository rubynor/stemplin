class ProjectShareInvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_share

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path, alert: t("project_shares.alert.invitation_not_found")
  end

  def show
    authorize! @share, with: ProjectShareInvitationPolicy
    @shares = @share.acceptable? ? answerable_shares : [ @share ]
    @organizations = eligible_organizations
    @admin_elsewhere = current_user.access_infos.organization_admin.exists?
  end

  def accept
    authorize! @share, with: ProjectShareInvitationPolicy
    @shares = answerable_shares
    organization = eligible_organizations.find { |candidate| candidate.id == params[:organization_id].to_i }
    return redirect_to(project_share_invitation_path(@share.invitation_token), alert: t("project_shares.alert.pick_organization")) unless organization

    # Projects the organization already has through another invitation stay as they are.
    accepting = @shares.reject { |share| already_shared_with?(organization, share.project) }
    ActiveRecord::Base.transaction do
      accepting.each { |share| share.accept!(organization) }
      current_user.activate_organization!(organization)
    end

    if accepting.one?
      redirect_to shared_project_path(accepting.first.project), notice: t("project_shares.notice.accepted", project: accepting.first.project.name)
    else
      redirect_to shared_projects_path, notice: t("project_shares.notice.accepted_many", count: accepting.size)
    end
  end

  def reject
    authorize! @share, with: ProjectShareInvitationPolicy
    shares = answerable_shares
    ActiveRecord::Base.transaction { shares.each(&:reject!) }

    notice = shares.one? ? t("project_shares.notice.rejected", project: @share.project.name) : t("project_shares.notice.rejected_many", count: shares.size)
    redirect_to root_path, notice: notice
  end

  private

  def set_share
    @share = authorized_scope(ProjectShare, type: :relation, with: ProjectShareInvitationPolicy).find_by!(invitation_token: params[:token])
  end

  def answerable_shares
    authorized_scope(ProjectShare, type: :relation, with: ProjectShareInvitationPolicy)
      .merge(@share.open_invitations_alongside).includes(project: :client).order(:created_at).to_a
  end

  # Organizations the user administers that don't own the projects and don't already have all of them.
  def eligible_organizations
    owner = @share.project.organization
    current_user.access_infos.organization_admin.includes(:organization).map(&:organization)
      .reject { |organization| organization == owner || @shares.all? { |share| already_shared_with?(organization, share.project) } }
      .sort_by(&:name)
  end

  def already_shared_with?(organization, project)
    Project.shared_with(organization).exists?(project.id)
  end
end
