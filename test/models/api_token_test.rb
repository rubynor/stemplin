require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  setup do
    @user = users(:ron)
  end

  test "a new token can be looked up by its plaintext" do
    token = @user.api_tokens.create!(name: "Laptop")

    assert_equal token, ApiToken.find_by_plaintext(token.plaintext)
  end

  test "the plaintext is not stored" do
    token = @user.api_tokens.create!(name: "Laptop")

    assert_nil ApiToken.find(token.id).plaintext
    assert_not_includes ApiToken.find(token.id).attributes.values, token.plaintext
  end

  test "each token gets its own secret" do
    first = @user.api_tokens.create!(name: "Laptop")
    second = @user.api_tokens.create!(name: "Server")

    assert_not_equal first.plaintext, second.plaintext
  end

  test "a label is required" do
    token = @user.api_tokens.build(name: " ")

    assert_not token.save
    assert token.errors.added?(:name, :blank)
  end

  test "a blank or unknown plaintext finds nothing" do
    @user.api_tokens.create!(name: "Laptop")

    assert_nil ApiToken.find_by_plaintext(nil)
    assert_nil ApiToken.find_by_plaintext("")
    assert_nil ApiToken.find_by_plaintext("not-a-token")
  end

  test "regenerating replaces the secret and keeps the label" do
    token = @user.api_tokens.create!(name: "Laptop")
    old_plaintext = token.plaintext

    new_plaintext = token.regenerate!

    assert_nil ApiToken.find_by_plaintext(old_plaintext)
    assert_equal token, ApiToken.find_by_plaintext(new_plaintext)
    assert_equal "Laptop", token.reload.name
  end

  test "a user is found by any of their tokens" do
    laptop = @user.api_tokens.create!(name: "Laptop")
    server = @user.api_tokens.create!(name: "Server")

    assert_equal @user, User.find_by_api_token(laptop.plaintext)
    assert_equal @user, User.find_by_api_token(server.plaintext)
  end

  test "a destroyed token no longer finds its user, while the others still do" do
    laptop = @user.api_tokens.create!(name: "Laptop")
    server = @user.api_tokens.create!(name: "Server")

    laptop.destroy!

    assert_nil User.find_by_api_token(laptop.plaintext)
    assert_equal @user, User.find_by_api_token(server.plaintext)
  end
end
