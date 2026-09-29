# Only the invited address may answer, so a forwarded link can't pull the project into another organization.
class ProjectShareInvitationPolicy < ApplicationPolicy
  def show?
    invited?
  end

  %i[ accept reject ].each do |action|
    define_method("#{action}?") { invited? && record.acceptable? }
  end

  scope_for :relation do |relation|
    relation.where(invited_email: user.email.downcase)
  end

  private

  def invited?
    record.invited_email == user.email.downcase
  end
end
