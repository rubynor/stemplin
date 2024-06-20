class TimeRegsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_time_reg, only: [ :toggle_active, :edit_modal, :update, :destroy, :delete_confirmation ]
  before_action :set_clients, only: [ :index, :new_modal, :create, :edit_modal, :update ]
  before_action :set_chosen_date, only: [ :index, :new_modal, :create, :edit_modal, :update ]
  before_action :set_project, only: [ :create, :update ]
  verify_authorized except: %i[ index create update_tasks_select ]

  require "activerecord-import/base"
  require "csv"
  include TimeRegsHelper

  def index
    @time_regs_week = authorized_scope(TimeReg, type: :relation, as: :own).between_dates(@chosen_date.beginning_of_week, @chosen_date.end_of_week)
    @time_regs = @time_regs_week.on_date(@chosen_date)
    @total_minutes_day = @time_regs.sum(&:current_minutes)
    @minutes_by_day = minutes_by_day_of_week(@chosen_date, current_user)
    @time_reg = authorized_scope(TimeReg, type: :relation, as: :own).new(date_worked: @chosen_date)
    @total_minutes_week = @time_regs_week.sum(&:current_minutes)
    @active_time_reg = authorized_scope(TimeReg, type: :relation, as: :own).all_active.first
    @current_minutes = @active_time_reg&.current_minutes
  end

  def new_modal
    @time_reg = authorized_scope(TimeReg, type: :relation, as: :own).new
    authorize! @time_reg
  end

  def create
    @time_reg = current_user.time_regs.new(time_reg_params.except(:project_id, :minutes_string))

    if @time_reg.save
      redirect_to time_regs_path(date: @time_reg.date_worked)
    else
      flash.now[:alert] = "Unable to create time entry"
      render :new_modal, status: :unprocessable_entity, formats: [ :html, :turbo_stream ]
    end
  end

  def update
    if @time_reg.update(time_reg_params.except(:project_id, :minutes_string))
      redirect_to time_regs_path(date: @time_reg.date_worked)
    else
      render :edit_modal, status: :unprocessable_entity, formats: [ :html, :turbo_stream ]
    end
  end

  def destroy
    @time_reg.destroy!
    redirect_to time_regs_path(date: @time_reg.date_worked)

  rescue ActiveRecord::RecordNotDestroyed
    flash[:alert] = "Unable to delete time registration"
    redirect_to time_regs_path
  end

  def toggle_active
    @time_reg.toggle_active
    redirect_to time_regs_path(date: @time_reg.date_worked)

  rescue ActiveRecord::RecordInvalid => e
    flash[:alert] = e.record.errors.full_messages.to_sentence
    redirect_to time_regs_path(date: @time_reg.date_worked)
  end

  # exports the time_regs in a project to a .CSV
  def export
    project = authorized_scope(Project, type: :relation).find(params[:project_id])
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
    @name_id_pairs = @tasks.assigned_task_names_and_ids(params[:project_id])
    render partial: "/time_regs/select", locals: { tasks: @name_id_pairs }
  end

  def edit_modal
    @assigned_tasks = authorized_scope(Task, type: :relation, as: :own).assigned_tasks(@time_reg.project&.id)
  end

  private

  def time_reg_params
    params.require(:time_reg).permit(:notes, :minutes, :assigned_task_id, :date_worked, :project_id, :minutes_string)
  end

  def set_time_reg
    @time_reg = TimeReg.find(params[:time_reg_id] || params[:id])
    authorize! @time_reg
  end

  def set_clients
    @clients ||= authorized_scope(Project, type: :relation).group_by(&:client).map do |client, projects|
      OpenStruct.new(name: client.name, items: projects)
    end
  end
  def set_chosen_date
    @chosen_date = params.has_key?(:date) ? Date.parse(params[:date]) : Date.today
  end

  def set_project
    @project = authorized_scope(Project, type: :relation, as: :own).find(time_reg_params[:project_id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Project not found, kindly select a valid project."
  end
end
