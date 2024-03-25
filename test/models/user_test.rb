require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "#role returns 'user' or 'admin'" do
    user = users(:joe)
    admin = users(:ron)

    assert_equal "user", user.role
    assert_equal "admin", admin.role
  end
end
