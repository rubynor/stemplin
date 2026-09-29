require "csv"

module Shared
  class ProjectsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_filter
    before_action :set_project, only: %i[show export destroy]

    rescue_from ActiveRecord::RecordNotFound do
      redirect_to shared_projects_path, alert: t("shared_projects.alert.not_found")
    end

    def index
      authorize!
      projects = authorized_scope(Project, type: :relation).includes(client: :organization).order(:name)
      time_regs = authorized_scope(TimeReg, type: :relation)
        .between_dates(@filter.start_date, @filter.end_date)
        .includes(assigned_task: :project)
        .group_by { |time_reg| time_reg.assigned_task.project_id }

      @summaries_by_owner = projects
        .map { |project| ProjectSummary.new(project: project, time_regs: time_regs.fetch(project.id, [])) }
        .group_by(&:owner)
        .sort_by { |owner, _| owner.name }
      @shares_by_project = authorized_scope(ProjectShare, type: :relation).index_by(&:project_id)
    end

    def show
      authorize! @project
      @time_regs = filtered_time_regs.includes(:user, assigned_task: %i[task project]).order(date_worked: :desc, created_at: :desc)
      @summary = ProjectSummary.new(project: @project, time_regs: @time_regs)
      @consultants = User.where(id: period_time_regs.select(:user_id)).ordered_by_name
      @tasks = Task.where(id: AssignedTask.where(id: period_time_regs.select(:assigned_task_id)).select(:task_id)).order(:name)
    end

    def export
      authorize! @project
      time_regs = filtered_time_regs.includes(:user, assigned_task: %i[task project]).order(:date_worked, :created_at)
      summary = ProjectSummary.new(project: @project, time_regs: time_regs)

      # No email column: the recipient sees who did the work, not how to reach them.
      csv = CSV.generate(headers: true) do |rows|
        rows << %w[date project task consultant notes minutes hours amount currency]
        time_regs.each do |time_reg|
          rows << [ time_reg.date_worked, @project.name, time_reg.assigned_task.task&.name, time_reg.user.name, time_reg.notes,
                   time_reg.minutes, (time_reg.minutes / 60.0).round(2), (summary.amount_for(time_reg) / 100.0).round(2), summary.currency ]
        end
      end
      send_data csv, type: "text/csv", filename: "#{@project.name.parameterize}_#{@filter.start_date}_#{@filter.end_date}.csv"
    end

    def destroy
      authorize! @project
      share = authorized_scope(ProjectShare, type: :relation).find_by!(project: @project)
      authorize! share
      share.revoke!
      redirect_to shared_projects_path, notice: t("shared_projects.notice.removed", project: @project.name)
    end

    private

    def filter_params
      params.fetch(:filter, {}).permit(:start_date, :end_date, :time_frame, user_ids: [], task_ids: [])
    end

    def set_filter
      @filter = Reports::Filter.new(filter_params)
    end

    def set_project
      @project = authorized_scope(Project, type: :relation).find(params[:id])
    end

    def period_time_regs
      authorized_scope(TimeReg, type: :relation)
        .where(assigned_task: @project.assigned_tasks)
        .between_dates(@filter.start_date, @filter.end_date)
    end

    def filtered_time_regs
      time_regs = period_time_regs
      time_regs = time_regs.by_users(@filter.user_ids) if @filter.user_ids.present?
      time_regs = time_regs.by_tasks(@filter.task_ids) if @filter.task_ids.present?
      time_regs
    end
  end
end
