class ReportPolicy < ApplicationPolicy
  %i[ index detailed ].each do |action|
    define_method("#{action}?") { true }
  end
end
