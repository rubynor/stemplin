class ReportsController < ApplicationController
  before_action :authenticate_user!

  # exports the the report as a .CSV
  def export
    time_regs = JSON.parse(params[:time_regs_hash])
    csv_data = CSV.generate(headers: true) do |csv|
      # Add CSV header row
      csv << ['date', 'client', 'project', 'task', 'notes', 'minutes', 'first name', 'last name', 'email']
      # Add CSV data rows for each time_reg
      time_regs.each do |time_reg|
        csv << [time_reg['date'], time_reg['client'], time_reg['project'], time_reg['task'],
                time_reg['notes'], time_reg['minutes'], time_reg['user_first_name'], time_reg['user_last_name'], time_reg['user_email']]
      end
    end
    # downloads the report as a .CSV
    send_data csv_data, filename: "#{Time.now.to_i}_time_regs_for_custom_report.csv"
  end

  private

  # returns a hash of the correrct timeframe options
  def get_timeframe_options
    thisMonthName = I18n.t('date.month_names')[Date.today.month]
    lastMonthName = I18n.t('date.month_names')[Date.today.month - 1]
    timeframeOptions = {
      'All Time' => 'allTime',
      'Custom' => 'custom',
      'This week' => 'thisWeek',
      'Last week' => 'lastWeek',
      "This Month (#{thisMonthName})" => 'thisMonth',
      "Last month (#{lastMonthName})" => 'lastMonth'
    }
  end

  # gets all the time_regs for the report with the filters in the report object
  def get_time_regs(report, users, projects, tasks)
    # includes tables to decrease the number of queries
    time_regs = TimeReg.includes(
      :task,
      :user,
      membership: [:user],
      assigned_task: %i[project task],
      project: :client
    )

    # sets a timeframe unless it is allTime
    time_regs = time_regs.where(date_worked: report.date_start..report.date_end) unless report.timeframe == 'allTime'

    # filters the time_regs to show the correct ones
    time_regs = time_regs.where(membership: { user_id: users, project_id: projects })
                         .where(assigned_task: { task_id: tasks })
                         .order(date_worked: :desc, created_at: :desc)

    # converts a time_reg to hash and maps it
    time_regs.map do |time_reg|
      {
        date: time_reg.date_worked,
        client: time_reg.project.client.name,
        project: time_reg.project.name,
        task: time_reg.task.name,
        user: time_reg.user.name,
        notes: time_reg.notes,
        minutes: time_reg.minutes,
        user_first_name: time_reg.user.first_name,
        user_last_name: time_reg.user.last_name,
        user_email: time_reg.user.email
      }
    end
  end

  # groupes the time_regs for the different columns
  def group_time_regs(time_regs_hash, group)
    if group == 'task'
      grouped_report = time_regs_hash.group_by { |time_reg| time_reg[:task] }
    elsif group == 'user'
      grouped_report = time_regs_hash.group_by { |time_reg| time_reg[:user] }
    elsif group == 'date'
      grouped_report = time_regs_hash.group_by { |time_reg| time_reg[:date] }
    elsif group == 'project'
      grouped_report = time_regs_hash.group_by { |time_reg| time_reg[:project] }
    elsif group == 'client'
      grouped_report = time_regs_hash.group_by { |time_reg| time_reg[:client] }
    end
    grouped_report
  end

  # sets the timeframe for the report if it is custom or allTime
  def set_dates(report)
    if report.timeframe == 'allTime'
      report.date_start = nil
      report.date_end = nil
    else
      report = set_timeframe(report)
    end
    report
  end

  # sets the reports timeframe if it is not allTime or custom
  def set_timeframe(report)
    timeframe = report.timeframe
    today = Date.today

    if timeframe == 'thisWeek'
      new_date_start = today.beginning_of_week
      new_date_end = today
    elsif timeframe == 'lastWeek'
      new_date_start = today.last_week.beginning_of_week
      new_date_end = today.last_week.end_of_week
    elsif timeframe == 'thisMonth'
      new_date_start = today.beginning_of_month
      new_date_end = today
    elsif timeframe == 'lastMonth'
      new_date_start = today.last_month.beginning_of_month
      new_date_end = today.last_month.end_of_month
    end
    report.date_start = new_date_start
    report.date_end = new_date_end

    report
  end
end
