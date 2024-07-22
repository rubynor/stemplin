class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize!

  def show
    set_form_data
    @structured_report_data = {}
    @detailed_report_data = OpenStruct.new
  end

  def update
    set_form_data

    client_ids_for_report = @form_data.selected_client_ids.presence || authorized_scope(Client, type: :relation).ids
    project_ids_for_report = @form_data.selected_project_ids.presence || authorized_scope(Project, type: :relation).ids
    user_ids_for_report = @form_data.selected_user_ids.presence || authorized_scope(User, type: :relation).ids
    task_ids_for_report = @form_data.selected_task_ids.presence || authorized_scope(Task, type: :relation).ids

    time_regs = authorized_scope(TimeReg, type: :relation).for_report(client_ids_for_report, project_ids_for_report, user_ids_for_report, task_ids_for_report)
                       .where(date_worked: (@selected_start_date..@selected_end_date))

    @structured_report_data = time_regs.group_by { |reg| reg[:date_worked] }.sort_by { |key| key  }

    clients = authorized_scope(Client, type: :relation).joins(:time_regs).where(time_regs: { id: time_regs }).distinct
    projects = authorized_scope(Project, type: :relation).joins(:time_regs).where(time_regs: { id: time_regs }).distinct
    tasks = authorized_scope(Task, type: :relation).joins(:time_regs).where(time_regs: { id: time_regs }).distinct
    users = authorized_scope(User, type: :relation).joins(:time_regs).where(time_regs: { id: time_regs }).distinct
    total_billable_minutes = time_regs.joins(:project).where(project: { billable: true }).sum(&:minutes)
    total_minutes = time_regs.sum(&:minutes)

    @detailed_report_data = OpenStruct.new(
      time_regs: time_regs,
      total_billable_minutes: total_billable_minutes,
      total_minutes: total_minutes,
      clients: clients,
      projects: projects,
      tasks: tasks,
      users: users,
    )

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
end
