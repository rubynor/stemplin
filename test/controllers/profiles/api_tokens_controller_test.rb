require "test_helper"

module Profiles
  class ApiTokensControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:ron)
      @other_user = users(:joe)
    end

    test "create requires sign in" do
      post profile_api_tokens_path, params: { api_token: { name: "Laptop" } }

      assert_redirected_to new_user_session_path
      assert_empty @user.api_tokens
    end

    test "create adds a labelled token and shows its secret exactly once, with a warning" do
      sign_in @user

      post profile_api_tokens_path, params: { api_token: { name: "Laptop" } }

      assert_response :ok
      assert_equal "text/vnd.turbo-stream.html", response.media_type
      token = @user.api_tokens.sole
      assert_equal "Laptop", token.name
      secret = response.body[/<code[^>]*>([^<]+)<\/code>/, 1]
      assert_equal token, ApiToken.find_by_plaintext(secret)
      assert_equal 1, response.body.scan(/<code[^>]*>#{Regexp.escape(secret)}<\/code>/).count
      assert_includes response.body, I18n.t("api_token.one_time_notice")
    end

    test "creating a second token leaves the first one working" do
      first = @user.api_tokens.create!(name: "Laptop")
      sign_in @user

      post profile_api_tokens_path, params: { api_token: { name: "Server" } }

      assert_equal %w[Laptop Server], @user.api_tokens.order(:id).pluck(:name)
      assert_equal @user, User.find_by_api_token(first.plaintext)
    end

    test "create without a label is rejected and explained" do
      sign_in @user

      post profile_api_tokens_path, params: { api_token: { name: "" } }

      assert_response :unprocessable_entity
      assert_empty @user.api_tokens.reload
      assert_match(/Name can.+t be blank/, response.body)
    end

    test "the profile lists tokens by label and never shows a secret again" do
      token = @user.api_tokens.create!(name: "Laptop")
      sign_in @user

      get profile_path

      assert_response :success
      assert_select "#api_token_section", text: /Laptop/
      assert_not_includes response.body, token.plaintext
      assert_not_includes response.body, I18n.t("api_token.one_time_notice")
    end

    test "the profile does not list other people's tokens" do
      @other_user.api_tokens.create!(name: "Joe's server")
      sign_in @user

      get profile_path

      assert_select "#api_token_section", text: /Joe's server/, count: 0
    end

    test "update renames a token without changing its secret" do
      token = @user.api_tokens.create!(name: "Laptop")
      sign_in @user

      patch profile_api_token_path(token), params: { api_token: { name: "Work laptop" } }

      assert_redirected_to profile_path
      assert_equal "Work laptop", token.reload.name
      assert_equal token, ApiToken.find_by_plaintext(token.plaintext)
    end

    test "update to a blank label is rejected and explained" do
      token = @user.api_tokens.create!(name: "Laptop")
      sign_in @user

      patch profile_api_token_path(token), params: { api_token: { name: "" } }

      assert_response :unprocessable_entity
      assert_equal "Laptop", token.reload.name
      assert_match(/Name can.+t be blank/, response.body)
    end

    test "someone else's token cannot be renamed" do
      token = @other_user.api_tokens.create!(name: "Joe's server")
      sign_in @user

      patch profile_api_token_path(token), params: { api_token: { name: "Mine now" } }

      assert_response :not_found
      assert_equal "Joe's server", token.reload.name
    end

    test "destroy removes the token, which stops working, and keeps the others" do
      laptop = @user.api_tokens.create!(name: "Laptop")
      server = @user.api_tokens.create!(name: "Server")
      sign_in @user

      delete profile_api_token_path(laptop)

      assert_redirected_to profile_path
      assert_equal [ server ], @user.api_tokens.to_a
      assert_nil User.find_by_api_token(laptop.plaintext)
      assert_equal @user, User.find_by_api_token(server.plaintext)
    end

    test "someone else's token cannot be destroyed" do
      token = @other_user.api_tokens.create!(name: "Joe's server")
      sign_in @user

      delete profile_api_token_path(token)

      assert_response :not_found
      assert ApiToken.exists?(token.id)
    end

    test "destroy requires sign in" do
      token = @user.api_tokens.create!(name: "Laptop")

      delete profile_api_token_path(token)

      assert_redirected_to new_user_session_path
      assert ApiToken.exists?(token.id)
    end
  end
end
