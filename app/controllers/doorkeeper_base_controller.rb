# frozen_string_literal: true

class DoorkeeperBaseController < ApplicationController
  skip_verify_authorized
  skip_before_action :redirect_if_no_organization
end
