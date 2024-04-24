class MembershipsController < ApplicationController
  before_action :authenticate_user!

  def new
    @project = authorized_scope(Project, type: :relation).find(params[:id])
  end

  # adds a member to the project
  def create
    @email = membership_params[:email]
    @project = authorized_scope(Project, type: :relation).find(params[:project_id])
    @membership = @project.memberships.build

    authorize! @membership

    # checks if the user exists
    if authorized_scope(User, type: :relation).exists?(email: @email)
      @user = authorized_scope(User, type: :relation).find_by(email: @email)
      @membership.user_id = @user.id

      # checks if the user is already a member
      if @project.memberships.exists?(user_id: @user.id)
        flash[:alert] = "#{@email} #{t('alert.is_already_a_member_of_the_project')}"
      elsif @membership.save
        flash[:notice] = "#{@email} #{t('notice.was_added_to_the_project')}"
      end
    else
      flash[:alert] = "#{@email} #{t('alert.does_not_exist')}"
    end
    redirect_to request.referrer
  end

  def destroy
    @project = authorized_scope(Project, type: :relation).find(params[:project_id])
    @membership = @project.memberships.find(params[:id])

    authorize! @membership

    # tries to remove a user from the project
    if @project.memberships.count <= 1
      flash[:alert] = t('alert.cannot_remove_last_member_of_the_project')
    elsif @membership.time_regs.count >= 1
      flash[:alert] = t('alert.member_has_time_entries_in_this_project')
    else
      flash[:notice] = "#{@membership.user.email} #{t('notice.has_been_removed_from_the_project')}"
      @membership.destroy
    end
    redirect_to request.referrer
  end

  private

  def membership_params
    params.require(:membership).permit(:email)
  end
end
