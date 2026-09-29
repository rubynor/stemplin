require "test_helper"

class SentryHelperTest < ActionView::TestCase
  setup { @user = users(:joe) }

  test "renders nothing where Sentry is disabled" do
    with_env("SENTRY_KEY" => "https://key@sentry.example/1") do
      assert_nil sentry_meta_tags
    end
  end

  test "renders nothing without a DSN" do
    with_env("SENTRY_KEY" => nil, "SENTRY_FRONTEND_DSN" => nil) do
      @sentry_enabled = true
      assert_nil sentry_meta_tags
    end
  end

  test "configures the browser SDK with the DSN, user and organization" do
    @current_user = @user
    with_env("SENTRY_KEY" => "https://backend@sentry.example/1", "SENTRY_FRONTEND_DSN" => "https://frontend@sentry.example/2") do
      @sentry_enabled = true
      html = sentry_meta_tags

      assert_includes html, %(<meta name="sentry-dsn" content="https://frontend@sentry.example/2">)
      assert_includes html, %(<meta name="sentry-environment" content="test">)
      assert_includes html, %(<meta name="sentry-user-id" content="#{@user.id}">)
      assert_includes html, %(<meta name="sentry-organization-id" content="#{@user.current_organization.id}">)
    end
  end

  private

  # The real check is false in test, where the Ruby SDK is disabled.
  def sentry_enabled? = @sentry_enabled || super
  def current_user = @current_user

  def with_env(values)
    previous = values.keys.index_with { |key| ENV[key] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    previous.each { |key, value| ENV[key] = value }
  end
end
