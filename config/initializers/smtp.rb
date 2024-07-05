# @Note: config to support mailer, not needed if we keep `.send_with_sendgrid`

ActionMailer::Base.smtp_settings = {
  domain: Stemplin.config.http_url,
  address:        "smtp.sendgrid.net",
  port:            587,
  authentication: :plain,
  user_name:      "apikey",
  password:       ENV["SENDGRID_API_KEY"]
}
