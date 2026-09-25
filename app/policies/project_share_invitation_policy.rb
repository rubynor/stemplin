# Answering an invitation to a shared project. The link is only good for the address it was sent to,
# so a forwarded link cannot pull another company's project into the wrong organization.
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
