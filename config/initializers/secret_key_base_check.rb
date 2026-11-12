# docker-compose.yml used to fall back to this value. Anyone who knows it can
# forge sessions, so the app refuses to start with it.
if !Rails.env.local? && ENV["SECRET_KEY_BASE"] == "change_this_to_a_secure_secret_key"
  raise "SECRET_KEY_BASE is still the placeholder value. Generate one with `openssl rand -hex 64` and set it."
end
