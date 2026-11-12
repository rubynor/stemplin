class Users::SessionsController < Devise::SessionsController
  include AuthRateLimiting
end
