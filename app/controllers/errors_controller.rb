class ErrorsController < ApplicationController
  skip_verify_authorized

  layout "error"

  def not_found
    puts "4040404040404"
    render status: 404
  end

  def internal_server_error
    render status: 500
  end
end
