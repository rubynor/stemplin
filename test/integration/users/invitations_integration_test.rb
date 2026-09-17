require "test_helper"

class Users::InvitationsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @inviting_admin = users(:organization_admin)
    @invited = User.invite!({ email: "newcomer@example.com" }, @inviting_admin) do |user|
      user.skip_invitation = true
    end
    @raw_token = @invited.raw_invitation_token
  end

  test "invited user accepts the invitation and gets a usable account" do
    assert @invited.pending_invitation?

    get accept_user_invitation_path(invitation_token: @raw_token)
    assert_response :success

    put user_invitation_path, params: {
      user: {
        invitation_token: @raw_token,
        first_name: "New",
        last_name: "Comer",
        password: "Str0ng-Password!",
        password_confirmation: "Str0ng-Password!"
      }
    }
    assert_response :redirect

    @invited.reload
    assert_not @invited.pending_invitation?
    assert_not_nil @invited.invitation_accepted_at
    assert @invited.valid_password?("Str0ng-Password!")
    assert_equal "New", @invited.first_name
  end

  test "an invitation cannot be accepted with an unknown token" do
    put user_invitation_path, params: {
      user: {
        invitation_token: "not-a-real-token",
        first_name: "New",
        last_name: "Comer",
        password: "Str0ng-Password!",
        password_confirmation: "Str0ng-Password!"
      }
    }

    assert_response :unprocessable_content
    assert @invited.reload.pending_invitation?
  end

  test "an accepted invitation token cannot be replayed" do
    put user_invitation_path, params: {
      user: {
        invitation_token: @raw_token,
        first_name: "New",
        last_name: "Comer",
        password: "Str0ng-Password!",
        password_confirmation: "Str0ng-Password!"
      }
    }
    assert_response :redirect

    # Accepting signs the user in, so sign out to replay the token as a
    # stranger who got hold of the invitation link.
    delete destroy_user_session_path

    put user_invitation_path, params: {
      user: {
        invitation_token: @raw_token,
        first_name: "Someone",
        last_name: "Else",
        password: "Hijacked-Password!",
        password_confirmation: "Hijacked-Password!"
      }
    }

    assert_response :unprocessable_content
    @invited.reload
    assert @invited.valid_password?("Str0ng-Password!"), "a used invitation must not be able to reset the password"
    assert_equal "New", @invited.first_name
  end
end
