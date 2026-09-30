require "test_helper"

class LocaleScopeTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "a request in another language leaves the locale as it was" do
    user = users(:organization_admin)
    user.update!(locale: "nb")
    sign_in user

    get root_path

    assert_equal I18n.default_locale, I18n.locale
  end
end
