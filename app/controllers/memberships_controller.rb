class MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_membership
  before_action :authorize!

  def new
    @project = authorized_scope(Project, type: :relation).find(params[:id])
  end

  # adds a member to the project
  def create
    @email = membership_params[:email]
    @project = authorized_scope(Project, type: :relation).find(params[:project_id])

    # checks if the user exists
    if authorized_scope(User, type: :relation).exists?(email: @email)
      @user = authorized_scope(User, type: :relation).find_by(email: @email)
      @membership = @project.memberships.build(user_id: @user.id)

      # checks if the user is already a member
      if @project.memberships.exists?(user_id: @user.id)
        flash[:alert] = "#{@email} is already a member of the project"
      elsif @membership.save
        flash[:notice] = "#{@email} was added to the project"
      end
    else
      flash[:alert] = "#{@email} does not exist"
    end
    redirect_to request.referrer
  end

  def destroy
    @project = authorized_scope(Project, type: :relation).find(params[:project_id])
    @membership = @project.memberships.find(params[:id])

    # tries to remove a user from the project
    if @project.memberships.count <= 1
      flash[:alert] = "cannot remove last member of the project"
    elsif @membership.time_regs.count >= 1
      flash[:alert] = "Member has time entries in this project"
    else
      flash[:notice] = "#{@membership.user.email} has been removed from the project"
      @membership.destroy
    end
    redirect_to request.referrer
  end

  private

  def membership_params
    params.require(:membership).permit(:email)
  end

  # ensures that only members have access
  def ensure_membership
    project = authorized_scope(Project, type: :relation).find(params[:project_id])

    return if project.memberships.exists?(user_id: current_user)

    flash[:alert] = "Access denied"
    redirect_to root_path
  end
end
