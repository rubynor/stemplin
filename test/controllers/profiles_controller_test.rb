require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:ron)
  end

  test "show requires sign in" do
    get profile_path

    assert_redirected_to new_user_session_path
  end

  test "show renders inside the app, with the navigation bar and the current details" do
    sign_in @user

    get profile_path

    assert_response :success
    assert_select "header nav a[href=?]", reports_path
    assert_select "#profile_personal input[name='user[first_name]'][value=?]", "Ron"
    assert_select "#profile_personal input[name='user[last_name]'][value=?]", "Done"
    assert_select "#profile_personal input[name='user[email]'][value=?]", "ron@example.com"
  end

  test "the section navigation has a link to every card on the page, and nothing else" do
    sign_in @user

    get profile_path

    cards = css_select("main section[id]").map { |section| section["id"] }
    links = css_select("main nav a").map { |link| link["href"] }
    assert_equal 5, cards.size
    assert_equal cards.map { |id| "##{id}" }, links
  end

  test "the navigation bar links to the profile" do
    sign_in @user

    get reports_path

    assert_select "header a[href=?]", profile_path, minimum: 1
  end

  test "show offers to generate a token" do
    sign_in @user

    get profile_path

    assert_response :success
    assert_select "#api_token_section form[action=?] input[name='api_token[name]']", profile_api_tokens_path
  end

  test "the CLI setup shows the install command" do
    sign_in @user

    get profile_path

    assert_select "#profile_cli code", text: /curl .*stemplin-cli.*install\.sh \| bash/
  end

  test "the CLI setup gives this server's address, not a hard-coded one" do
    sign_in @user
    host! "time.example.org"

    get profile_path

    assert_select "#profile_cli code", text: "http://time.example.org"
  end

  test "the CLI setup gives the id of the organization the user is working in" do
    sign_in @user
    organization = @user.current_organization

    get profile_path

    assert_select "#profile_cli code", text: organization.id.to_s
    assert_select "#profile_cli", text: /#{Regexp.escape(organization.name)}/
  end

  # Claude Code only loads a skill from a folder of its own holding SKILL.md.
  # A loose .md file in ~/.claude/skills is silently ignored.
  test "the Claude skill command installs into a folder of its own" do
    sign_in @user

    get profile_path

    assert_select "#profile_claude code", text: %r{curl .*stemplin-cli.*/skill/stemplin-api\.md -o ~/\.claude/skills/stemplin-api/SKILL\.md}
    assert_select "#profile_claude code", text: %r{mkdir -p ~/\.claude/skills/stemplin-api}
  end

  test "update requires sign in" do
    patch profile_path, params: { user: { first_name: "Rob" } }

    assert_redirected_to new_user_session_path
    assert_equal "Ron", @user.reload.first_name
  end

  test "the name changes without the current password" do
    sign_in @user

    patch profile_path, params: { user: { first_name: "Rob", last_name: "Roy", email: "ron@example.com" } }

    assert_redirected_to profile_path
    assert_equal "Rob Roy", @user.reload.name
  end

  test "a blank name is rejected and explained in the personal card" do
    sign_in @user

    patch profile_path, params: { user: { first_name: "", last_name: "Done", email: "ron@example.com" } }

    assert_response :unprocessable_entity
    assert_equal "Ron", @user.reload.first_name
    assert_select "#profile_personal", text: /can't be blank/
    assert_select "#profile_password", text: /can't be blank/, count: 0
  end

  test "changing the email without the current password is rejected" do
    sign_in @user

    patch profile_path, params: { user: { first_name: "Ron", last_name: "Done", email: "new@example.com" } }

    assert_response :unprocessable_entity
    assert_equal "ron@example.com", @user.reload.email
    assert_select "#profile_personal", text: /can't be blank/
  end

  test "changing the email with a wrong current password is rejected" do
    sign_in @user

    patch profile_path, params: { user: { first_name: "Ron", last_name: "Done", email: "new@example.com", current_password: "wrong" } }

    assert_response :unprocessable_entity
    assert_equal "ron@example.com", @user.reload.email
    assert_select "#profile_personal", text: /is invalid/
  end

  test "a rejected email change saves nothing else either" do
    sign_in @user

    patch profile_path, params: { user: { first_name: "Rob", last_name: "Done", email: "new@example.com" } }

    assert_equal "Ron", @user.reload.first_name
  end

  test "the email changes when the current password is given" do
    sign_in @user

    patch profile_path, params: { user: { first_name: "Ron", last_name: "Done", email: "new@example.com", current_password: "password" } }

    assert_redirected_to profile_path
    assert_equal "new@example.com", @user.reload.email
  end

  test "the same email typed in another case needs no password" do
    sign_in @user

    patch profile_path, params: { user: { first_name: "Rob", last_name: "Done", email: "RON@example.com" } }

    assert_redirected_to profile_path
    assert_equal "Rob", @user.reload.first_name
    assert_equal "ron@example.com", @user.email
  end

  test "the personal form cannot change the password" do
    sign_in @user

    patch profile_path, params: { user: { first_name: "Ron", last_name: "Done", email: "ron@example.com", password: "sneaked-in-1", password_confirmation: "sneaked-in-1" } }

    assert @user.reload.valid_password?("password")
  end
end
