# Keys for `encrypts` (used for Tripletex employee tokens). Credentials or ENV win;
# otherwise they are derived from secret_key_base so self-hosted installs need no extra setup.
# Rotating secret_key_base without setting these explicitly makes stored tokens unreadable.
Rails.application.configure do
  credentials = Rails.application.credentials.active_record_encryption || {}
  key_generator = Rails.application.key_generator

  {
    primary_key: "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY",
    deterministic_key: "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY",
    key_derivation_salt: "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"
  }.each do |name, env_key|
    config.active_record.encryption.public_send(
      "#{name}=",
      credentials[name] || ENV[env_key] || key_generator.generate_key("active_record_encryption.#{name}", 32).unpack1("H*")
    )
  end
end
