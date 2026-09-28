# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  def project_share_invitation_email
    share = ProjectShare.pending.first || ProjectShare.new(project: Project.first, invited_by: User.first, invited_email: "client@example.com", invitation_token: "preview")
    UserMailer.project_share_invitation_email(project_share: share)
  end
end
