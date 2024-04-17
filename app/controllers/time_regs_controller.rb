class TimeRegsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_time_reg, only: [ :toggle_active, :edit_modal, :update ]
  before_action :set_projects, only: [ :index, :new_modal, :create, :edit_modal ]
  before_action :set_chosen_date, only: [ :index, :new_modal, :create, :edit_modal ]
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
    # gives the time_reg all the attributes
    @project = nil

    if authorized_scope(Project, type: :relation).exists?(time_reg_params[:project_id])
      @project = Project.find(time_reg_params[:project_id])
      @time_reg = @project.time_regs.new(time_reg_params.except(:project_id, :minutes_string))
      @time_reg.membership = authorized_scope(Membership, type: :relation, as: :own).find_by(project: @project)

      @time_reg.active = @time_reg.minutes.zero? # start as active?
      @time_reg.updated = Time.now
    end

    respond_to do |format|
      if @project.present? && allowed_to?(:create?, @time_reg) && @time_reg.save
        format.turbo_stream
        format.html { redirect_to root_path(date: @time_reg.date_worked), notice: "Time entry has been created" }
      else
        format.turbo_stream
        format.html { redirect_to root_path(date: time_reg_params[:date_worked]), status: :unprocessable_entity }
      end
    end
  end

  def edit
    @time_reg = TimeReg.find(params[:id])
    authorize! @time_reg
    @projects = current_user.projects
    @assigned_tasks = authorized_scope(Task, type: :relation).joins(:assigned_tasks)
                          .where(assigned_tasks: { project_id: @time_reg.project.id })
                          .pluck(:name, "assigned_tasks.id")
  end

  def update
    respond_to do |format|
      if @time_reg.update(time_reg_params.except(:project_id, :minutes_string))
        format.turbo_stream
        format.html { redirect_to root_path(date: @time_reg.date_worked), notice: "Time entry has been updated" }
      else
        format.turbo_stream
        format.html { redirect_to root_path(date: @time_reg.date_worked), status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @time_reg = TimeReg.find(params[:id])
    authorize! @time_reg

    if @time_reg.destroy
      redirect_to root_path(date: @time_reg.date_worked)
      flash[:notice] = "Time entry has been deleted"
    else
      @projects = current_user.projects
      @assigned_tasks = authorized_scope(Task, type: :relation).joins(:assigned_tasks)
                            .where(assigned_tasks: { project_id: @time_reg.project.id })
                            .pluck(:name, "assigned_tasks.id")

      flash[:alert] = "cannot delete time entry"
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_active
    @project = @time_reg.project

    if @time_reg.minutes >= TimeReg::MINUTES_IN_A_DAY
      return redirect_to root_path(date: @time_reg.date_worked), alert: "Time entry cannot exceed 24 hours"
    end

    update_time_reg(current_status: @time_reg.active)
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

  def update_time_reg(current_status:)
    if current_status
      worked_minutes = (Time.now.to_i - @time_reg.updated.to_i) / 60
      @time_reg.minutes = [ @time_reg.minutes + worked_minutes, TimeReg::MINUTES_IN_A_DAY ].min
    else
      @time_reg.updated = Time.now
    end

    @time_reg.active = !current_status

    if @time_reg.save
      flash[:success] = {
        title: "Success", body: "Timer has been toggled #{current_status ? "off": "on"}"
      }

      redirect_to root_path(date: @time_reg.date_worked)
    end
  end

  def set_time_reg
    @time_reg = TimeReg.find(params[:time_reg_id] || params[:id])
    authorize! @time_reg
  end

  def set_projects
    @projects ||= authorized_scope(Project, type: :relation, as: :own).all
    end
  def set_chosen_date
    @chosen_date = params.has_key?(:date) ? Date.parse(params[:date]) : Date.today
  end
end
