class InviteUserForm
  include ActiveModel::Model

  attr_accessor :email, :role, :project_ids, :organization


  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :email_not_in_organization
  validate :valid_role

  def initialize(params = {}, organization = nil)
    self.email = params[:email]
    self.role = params[:role]
    self.project_ids = params[:project_ids]
    self.organization = organization
  end

  def email_not_in_organization
    user = User.find_by(email: email)
    user_confirmed = user.present? && !user.pending_invitation?
    errors.add(:email, :taken) if user_confirmed && user.access_info(self.organization).present?
  end

  def valid_role
    errors.add(:role, :invalid) unless AccessInfo.allowed_organization_roles.include?(role)
  end
end
