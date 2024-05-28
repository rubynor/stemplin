module Organizations
  class ReportPolicy < ApplicationPolicy
    [ :index? ].each do |action|
      define_method(action) do
        user.organization_admin?
      end
    end
  end
end
