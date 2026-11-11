class TimeLocksController < ApplicationController
  before_action :authenticate_user!

  def create
    organization = current_user.current_organization
    target = find_target_user
    # An unknown user gets an unattached lock, which the policy refuses.
    lock = TimeLock.new(organization: target && organization, user: target,
                        locked_by: current_user, period: parse_period)
    authorize! lock

    if lock.save
      flash[:notice] = t("tripletex.locks.locked_notice", month: month_name(lock.period))
    else
      flash[:alert] = lock.errors.full_messages.to_sentence
    end
    redirect_back fallback_location: root_path
  end

  def destroy
    lock = authorized_scope(TimeLock, type: :relation).find_by(id: params[:id]) || TimeLock.new
    authorize! lock

    if lock.sent?
      flash[:alert] = t("tripletex.locks.errors.already_sent")
    else
      lock.destroy!
      flash[:notice] = t("tripletex.locks.unlocked_notice", month: month_name(lock.period))
    end
    redirect_back fallback_location: root_path
  end

  private

  # Admins may lock for any member of the organization, archived ones included
  # (UserPolicy's relation scope covers them); everyone else only for themselves.
  def find_target_user
    return current_user if params[:user_id].blank?

    authorized_scope(User, type: :relation).find_by(id: params[:user_id])
  end

  def parse_period
    Date.strptime(params[:month].to_s, "%Y-%m")
  rescue Date::Error
    nil
  end

  def month_name(date)
    I18n.l(date, format: "%B %Y")
  end
end
