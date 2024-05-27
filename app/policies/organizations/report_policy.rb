module Organizations
  class ReportPolicy < ApplicationPolicy
    [ :index? ].each do |action|
      define_method(action) do
        true
      end
    end
  end
end
