class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize!

  def show
    set_form_data
    @structured_report_data = {}
  end

  def update
    set_form_data

    client_ids_for_report = @form_data.selected_client_ids.presence || authorized_scope(Client, type: :relation).ids
    project_ids_for_report = @form_data.selected_project_ids.presence || authorized_scope(Project, type: :relation).ids
    user_ids_for_report = @form_data.selected_user_ids.presence || authorized_scope(User, type: :relation).ids
    task_ids_for_report = @form_data.selected_task_ids.presence || authorized_scope(Task, type: :relation).ids

    time_regs = authorized_scope(TimeReg, type: :relation).for_report(client_ids_for_report, project_ids_for_report, user_ids_for_report, task_ids_for_report)
                       .where(date_worked: (@selected_start_date..@selected_end_date))

    if @form_data.detailed_report

      @structured_report_data = time_regs.group_by { |reg| reg[:date_worked] }.sort_by { |key| key  }

      clients = authorized_scope(Client, type: :relation).joins(:time_regs).where(time_regs: { id: time_regs }).distinct
      projects = authorized_scope(Project, type: :relation).joins(:time_regs).where(time_regs: { id: time_regs }).distinct
      tasks = authorized_scope(Task, type: :relation).joins(:time_regs).where(time_regs: { id: time_regs }).distinct
      users = authorized_scope(User, type: :relation).joins(:time_regs).where(time_regs: { id: time_regs }).distinct
      total_billable_minutes = time_regs.joins(:project).where(project: { billable_project: true }).sum(:minutes)
      total_minutes = time_regs.sum(:minutes)

      @detailed_report_data = OpenStruct.new(
        time_regs: time_regs,
        total_billable_minutes: total_billable_minutes,
        total_minutes: total_minutes,
        clients: clients,
        projects: projects,
        tasks: tasks,
        users: users,
      )

    else

      @structured_report_data = TimeRegsPresenter.new(time_regs).report_data(
        title: nil,
        keys: [ :client, :project, :task, :user ]
      )
    end
    if turbo_frame_request?
      render :show
    end
  end

  # exports the the report as a .CSV
  def export
    time_regs = JSON.parse(params[:time_regs_hash])
    csv_data = CSV.generate(headers: true) do |csv|
      # Add CSV header row
      csv << [ "date", "client", "project", "task", "notes", "minutes", "first name", "last name", "email" ]
      # Add CSV data rows for each time_reg
      time_regs.each do |time_reg|
        csv << [ time_reg["date"], time_reg["client"], time_reg["project"], time_reg["task"],
                time_reg["notes"], time_reg["minutes"], time_reg["user_first_name"], time_reg["user_last_name"], time_reg["user_email"] ]
      end
    end
    # downloads the report as a .CSV
    send_data csv_data, filename: "#{Time.now.to_i}_time_regs_for_custom_report.csv"
  end

  private

  def report_params
    return params unless params[:report]
    params.require(:report).permit(:start_date, :end_date, client_ids: [], project_ids: [], task_ids: [], user_ids: [])
  end

  def set_form_data
    @selected_start_date = Date.parse(report_params[:start_date]) if report_params[:start_date].present?
    @selected_end_date = Date.parse(report_params[:end_date]) if report_params[:end_date].present?
    @form_data = OpenStruct.new(
      selectable_clients: authorized_scope(Client, type: :relation).order(:name),
      selectable_projects: authorized_scope(Project, type: :relation).order(:name),
      selectable_tasks: authorized_scope(Task, type: :relation).order(:name),
      selectable_users: authorized_scope(User, type: :relation).order(:last_name),

      selected_client_ids: report_params[:client_ids].to_a.map(&:to_i),
      selected_project_ids: report_params[:project_ids].to_a.map(&:to_i),
      selected_user_ids: report_params[:user_ids].to_a.map(&:to_i),
      selected_task_ids: report_params[:task_ids].to_a.map(&:to_i),

      selected_start_date: (Date.parse(report_params[:start_date]) if report_params[:start_date].present?),
      selected_end_date: (Date.parse(report_params[:end_date]) if report_params[:end_date].present?),

      detailed_report: !!params[:detailed_report],
    )

    if @form_data.selected_client_ids.any?
      @form_data.selectable_projects = authorized_scope(Project, type: :relation).joins(:client)
                                              .where(client: { id: @form_data.selected_client_ids })
                                              .distinct.order(:name)
    end

    if @form_data.selected_project_ids.any?
      @form_data.selectable_tasks = authorized_scope(Task, type: :relation).joins(:projects)
                                        .where(projects: { id: @form_data.selected_project_ids })
                                        .distinct.order(:name)
    end

    if @form_data.selected_project_ids.any?
      @form_data.selectable_users = authorized_scope(User, type: :relation).joins(:projects)
                                        .where(projects: { id: @form_data.selected_project_ids })
                                        .distinct.order(:last_name)
    end
  end

  # returns a hash of the correrct timeframe options
  def get_timeframe_options
    thisMonthName = I18n.t("date.month_names")[Date.today.month]
    lastMonthName = I18n.t("date.month_names")[Date.today.month - 1]
    timeframeOptions = {
      "All Time" => "allTime",
      "Custom" => "custom",
      "This week" => "thisWeek",
      "Last week" => "lastWeek",
      "This Month (#{thisMonthName})" => "thisMonth",
      "Last month (#{lastMonthName})" => "lastMonth"
    }
  end

  # gets all the time_regs for the report with the filters in the report object
  def get_time_regs(report, users, projects, tasks)
    # includes tables to decrease the number of queries
    time_regs = authorized_scope(TimeReg, type: :relation).includes(
      :task,
      :user,
      membership: [ :user ],
      assigned_task: %i[project task],
      project: :client
    )

    # sets a timeframe unless it is allTime
    time_regs = time_regs.where(date_worked: report.date_start..report.date_end) unless report.timeframe == "allTime"

    # filters the time_regs to show the correct ones
    time_regs.where(membership: { user_id: users, project_id: projects })
                         .where(assigned_task: { task_id: tasks })
                         .order(date_worked: :desc, created_at: :desc)
  end

  # groupes the time_regs for the different columns
  def group_time_regs(time_regs_hash, group)
    if group == "task"
      grouped_report = time_regs_hash.group_by { |time_reg| time_reg[:task] }
    elsif group == "user"
      grouped_report = time_regs_hash.group_by { |time_reg| time_reg[:user] }
    elsif group == "date"
      grouped_report = time_regs_hash.group_by { |time_reg| time_reg[:date] }
    elsif group == "project"
      grouped_report = time_regs_hash.group_by { |time_reg| time_reg[:project] }
    elsif group == "client"
      grouped_report = time_regs_hash.group_by { |time_reg| time_reg[:client] }
    end
    grouped_report
  end

  # sets the timeframe for the report if it is custom or allTime
  def set_dates(report)
    if report.timeframe == "allTime"
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

    if timeframe == "thisWeek"
      new_date_start = today.beginning_of_week
      new_date_end = today
    elsif timeframe == "lastWeek"
      new_date_start = today.last_week.beginning_of_week
      new_date_end = today.last_week.end_of_week
    elsif timeframe == "thisMonth"
      new_date_start = today.beginning_of_month
      new_date_end = today
    elsif timeframe == "lastMonth"
      new_date_start = today.last_month.beginning_of_month
      new_date_end = today.last_month.end_of_month
    end
    report.date_start = new_date_start
    report.date_end = new_date_end

    report
  end
end
