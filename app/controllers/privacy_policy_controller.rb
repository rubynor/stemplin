class PrivacyPolicyController < ApplicationController
  # Public, static page: readable signed out, by every role, and by users who
  # have not finished onboarding yet.
  skip_verify_authorized

  def index
  end
end
