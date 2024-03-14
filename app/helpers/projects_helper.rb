module ProjectsHelper
  # sums a users minutes on a task in a project
  def grouped_time_regs(assigned_task)
    assigned_task.time_regs
                 .joins(membership: :user)
                 .group("users.email")
                 .pluck("users.email", "SUM(time_regs.minutes)")
  end

  def user_data(email)
    User.find_by(email:)
  end

  def format_float(number)
    number.to_s.gsub(".", ",")
  end
end
