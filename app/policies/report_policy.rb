class ReportPolicy < ApplicationPolicy
  [ :show?, :update?, :export? ].each do |action|
    define_method(action) { true }
  end
end
