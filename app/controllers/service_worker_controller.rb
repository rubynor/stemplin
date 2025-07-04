class ServiceWorkerController < ApplicationController
  protect_from_forgery except: :service_worker
  skip_verify_authorized

  def service_worker
  end

  def manifest
  end
end
