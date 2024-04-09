class AssignedTaskPolicy < ApplicationPolicy
  [ :new?, :create?, :destroy? ].each do |action|
    define_method(action) { user.admin? }
  end
end
