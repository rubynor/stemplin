class ServiceWorkerPolicy < ApplicationPolicy
  def manifest?
    true
  end

  def service_worker?
    true
  end
end
