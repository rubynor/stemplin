module Organizations
  class ReportPolicy < ApplicationPolicy
    %i[ index detailed ].each do |action|
      define_method("#{action}?") do
        true
      end
    end
  end
end
