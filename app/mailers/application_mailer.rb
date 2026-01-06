# Generates and sends an email
#
# @param headers [Hash] The email headers and content
# @option headers [String] :to The email recipient
# @option headers [String] :sendgrid_template (optional) The SendGrid template ID
# @option headers [Hash] :content The content to be passed to SendGrid
# @option headers[:content] [String] :subject (optional) The email subject (defaults to 'Stemplin' if not provided)
#
# @return [Mail::Message] The generated mail object
#
# @note If :sendgrid_template is not provided, the mailer will look for a template view as usual

class ApplicationMailer < ActionMailer::Base
  default from: Stemplin.config.emails.from
  layout "mailer"

  # Overrides the default behavior to accommodate SendGrid templates
  # when they are specified in the headers.

  def mail(headers = nil, &block)
    if headers&.key?(:sendgrid_template)
      handle_sendgrid_template(headers)
    else
      super(headers, &block)
    end
  end

  def handle_sendgrid_template(headers)
    return true unless Rails.env.production? || Rails.env.staging?

    mail = build_mail(headers)
    sg = SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])
    sg.client.mail._("send").post(request_body: mail.to_json)
  end

  private

  def build_mail(headers)
    mail = SendGrid::Mail.new
    mail.template_id = headers[:sendgrid_template]

    add_personalization(mail, headers) if headers[:content].present?

    mail.from = SendGrid::Email.new(email: Stemplin.config.emails.from)
    mail
  end

  def add_personalization(mail, headers)
    personalization = SendGrid::Personalization.new
    personalization.add_to(SendGrid::Email.new(email: headers[:to]))

    headers[:content]&.each do |key, value|
      personalization.add_dynamic_template_data(key => value)
    end

    mail.add_personalization(personalization)
  end
end
