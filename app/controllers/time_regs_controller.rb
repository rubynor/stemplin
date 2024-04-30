class TimeRegsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_time_reg, only: [ :toggle_active, :edit_modal, :update, :destroy ]
  before_action :set_projects, only: [ :index, :new_modal, :create, :edit_modal ]
  before_action :set_chosen_date, only: [ :index, :new_modal, :create, :edit_modal ]
  before_action :set_project, only: [ :create ]
  verify_authorized except: %i[ index create update_tasks_select ]

  require "activerecord-import/base"
  require "csv"
  include TimeRegsHelper

  def index
    @time_regs_week = authorized_scope(TimeReg, type: :relation, as: :own).between_dates(@chosen_date.beginning_of_week, @chosen_date.end_of_week)
    @time_regs = @time_regs_week.on_date(@chosen_date)
    @total_minutes_day = @time_regs.sum(:minutes)
    @minutes_by_day = minutes_by_day_of_week(@chosen_date, current_user)
    @time_reg = authorized_scope(TimeReg, type: :relation, as: :own).new(date_worked: @chosen_date)
    @total_minutes_week = @time_regs_week.sum(:minutes)
  end

  def new_modal
    @time_reg = authorized_scope(TimeReg, type: :relation, as: :own).new
    authorize! @time_reg
  end

  def create
    @time_reg = current_user.time_regs.new(time_reg_params.except(:project_id, :minutes_string))

    if @time_reg.save
      render turbo_stream: [
        turbo_flash(type: :success, data: t("notice.time_entry_has_been_logged")),
        turbo_stream.prepend(:time_regs_list, partial: "time_regs/time_reg", locals: { time_reg: @time_reg }),
        turbo_stream.action(:remove_modal, :modal)
      ]
    else
      render turbo_stream: turbo_stream.replace(:modal, partial: "time_regs/form", locals: {
        time_reg: @time_reg, chosen_date: @chosen_date, projects: @projects, title: "New time entry", assigned_tasks: @time_reg.project&.tasks
      })
    end
  end

  def update
    if @time_reg.update(time_reg_params.except(:project_id, :minutes_string))
      render turbo_stream: [
        turbo_flash(type: :success, data: t("notice.time_entry_has_been_updated")),
        turbo_stream.replace(dom_id(@time_reg), partial: "time_regs/time_reg", locals: { time_reg: @time_reg }),
        turbo_stream.action(:remove_modal, :modal)
      ]
    else
      @assigned_tasks = authorized_scope(Task, type: :relation, as: :own).assigned_tasks(@time_reg.project.id)

      render turbo_stream: turbo_stream.replace(:modal, partial: "time_regs/form", locals: {
        time_reg: @time_reg, chosen_date: @chosen_date, projects: @projects, title: "Edit time entry", assigned_tasks: @time_reg.project&.tasks
      })
    end
  end

  def destroy
    @time_reg.destroy!
    render turbo_stream: [
      turbo_flash(type: :success, data: t("notice.registration_was_successfully")),
      turbo_stream.remove(dom_id(@time_reg)),
      turbo_stream.action(:remove_modal, :modal)
    ]

  rescue ActiveRecord::RecordNotDestroyed
    render turbo_stream: turbo_flash(type: :alert, data: t("notice.unable_to_delete_time_registration"))
  end

  def toggle_active
    @time_reg.toggle_active
    @chosen_date = Date.today
    render turbo_stream: [
      turbo_flash(type: :success, data: "#{t("notice.time_entry_has_been_toggled")} #{@time_reg.active? ? t("notice._on"): t("notice._off")}"),
      turbo_stream.replace(dom_id(@time_reg), partial: "time_regs/time_reg", locals: { time_reg: @time_reg })
    ]

  rescue ActiveRecord::RecordInvalid => e
    render turbo_stream: turbo_flash(type: :alert, data: t("notice.unable_to_toggle_time_entry"))
  end

  # exports the time_regs in a project to a .CSV
  def export
    project = Project.find(params[:project_id])
    client = project.client
    time_regs = project.time_regs.includes(
      :task,
      :user,
      membership: [ :user ],
      assigned_task: %i[project task],
      project: :client
    )
    csv_data = CSV.generate(headers: true) do |csv|
      # Add CSV header row
      csv << [ "date", "client", "project", "task", "notes", "minutes", "first name", "last name", "email" ]
      # Add CSV data rows for each time_reg
      time_regs.each do |time_reg|
        csv << [ time_reg.date_worked, client.name, project.name, time_reg.assigned_task.task.name,
                time_reg.notes, time_reg.minutes, time_reg.user.first_name, time_reg.user.last_name, time_reg.user.email ]
      end
    end
    send_data csv_data, filename: "#{Time.now.to_i}_time_regs_for_#{project.name}.csv"
  end

  # changes the selection tasks to show tasks from a specific project
  def update_tasks_select
    @tasks = authorized_scope(Task, type: :relation, as: :own).all
    @name_id_pairs = @tasks.joins(:assigned_tasks).where(assigned_tasks: { project_id: params[:project_id] }).pluck(:name, "assigned_tasks.id")
    render partial: "/time_regs/select", locals: { tasks: @name_id_pairs }
  end

  def edit_modal
    @assigned_tasks = authorized_scope(Task, type: :relation, as: :own).assigned_tasks(@time_reg.project.id)
  end

  private

  def time_reg_params
    params.require(:time_reg).permit(:notes, :minutes, :assigned_task_id, :date_worked, :project_id, :minutes_string)
  end

  def set_time_reg
    @time_reg = TimeReg.find(params[:time_reg_id] || params[:id])
    authorize! @time_reg
  end

  def set_projects
    @projects ||= authorized_scope(Project, type: :relation, as: :own)
  end
  def set_chosen_date
    @chosen_date = params.has_key?(:date) ? Date.parse(params[:date]) : Date.today
  end

  def set_project
    @project = authorized_scope(Project, type: :relation, as: :own).find(time_reg_params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render turbo_stream: turbo_flash(type: :alert, data: I18n.t("alert.project_not_found"))
  end
end
