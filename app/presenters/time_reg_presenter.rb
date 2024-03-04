class TimeRegPresenter
  def initialize(time_reg)
    @time_reg = time_reg
  end

  def as_hash
    {
      date: @time_reg.date_worked,
      client: @time_reg.project.client.name,
      project: @time_reg.project.name,
      task: @time_reg.task.name,
      user: @time_reg.user.name,
      notes: @time_reg.notes,
      minutes: @time_reg.minutes,
      user_first_name: @time_reg.user.first_name,
      user_last_name: @time_reg.user.last_name,
      user_email: @time_reg.user.email
    }
  end
end