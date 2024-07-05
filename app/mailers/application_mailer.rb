class ApplicationMailer < ActionMailer::Base
  default from: Stemplin.config.emails.from
  layout "mailer"

  def send_mail(to:, subject:, body:)
    mail(
      to: to,
      subject: subject,
      body: body
    )
  end

  def send_with_sendgrid(to:, template_id:, personalization_data: {})
    return true unless Rails.env.production?

    mail = build_mail(to: to, template_id: template_id, personalization_data: personalization_data)
    send_email(mail)
  end

  private

  def build_mail(to:, template_id:, personalization_data: {})
    mail = SendGrid::Mail.new
    mail.template_id = template_id

    add_personalization(mail, to: to, personalization_data: personalization_data) if personalization_data.present?

    mail.from = SendGrid::Email.new(email: Stemplin.config.emails.from)
    mail
  end

  def add_personalization(mail, to:, personalization_data: {})
    personalization = SendGrid::Personalization.new
    personalization.add_to(SendGrid::Email.new(email: to))

    personalization_data.each do |key, value|
      personalization.add_dynamic_template_data(key => value)
    end

    mail.add_personalization(personalization)
  end

  def send_email(mail)
    data = mail.to_json

    sg = SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])
    response = sg.client.mail._("send").post(request_body: data)

    response.status_code
  end
end
