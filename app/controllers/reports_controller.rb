class ReportsController < AuthenticatedController
  before_action :authorize!
  before_action :set_time_regs

  def index
    @summary = Reports::Summary.new(
      time_regs: @time_regs,
    )
    @results = Reports::Result.new(time_regs: @time_regs, filter: @filter)
    authorize!
  end

  def detailed
    set_form_data

    total_billable_minutes = @time_regs.joins(:project).where(projects: { billable: true }).sum(&:minutes)
    total_minutes = @time_regs.sum(&:minutes)
    clients = authorized_scope(Client, type: :relation).joins(:time_regs).where(time_regs: { id: @time_regs }).distinct
    projects = authorized_scope(Project, type: :relation).joins(:time_regs).where(time_regs: { id: @time_regs }).distinct
    tasks = authorized_scope(Task, type: :relation).joins(:time_regs).where(time_regs: { id: @time_regs }).distinct
    users = authorized_scope(User, type: :relation).joins(:time_regs).where(time_regs: { id: @time_regs }).distinct

    @structured_report_data = @time_regs.group_by { |reg| reg.date_worked }.sort_by { |key| key  }
    @detailed_report_data = OpenStruct.new(
      time_regs: @time_regs,
      total_billable_minutes: total_billable_minutes,
      total_minutes: total_minutes,
      clients: clients,
      projects: projects,
      tasks: tasks,
      users: users,
    )
  end

  private

  def filter_params
    params.fetch(:filter, {}).permit(:start_date, :end_date, :category, :time_frame, client_ids: [], project_ids: [], user_ids: [], task_ids: [])
  end

  def set_time_regs
    @filter = Reports::Filter.new(filter_params)
    @time_regs = authorized_scope(TimeReg, type: :relation).between_dates(@filter.start_date, @filter.end_date)
    @time_regs = filtered_collection(@time_regs)
  end

  def filtered_collection(collection)
    Reports::Filter::FILTER_MAPPINGS.each do |filter_key, scope_method|
      if @filter.send(filter_key).present?
        collection = collection.send(scope_method, @filter.send(filter_key))
      end
    end

    collection
  end

  def set_form_data
    @form_data = OpenStruct.new(
      selectable_clients: authorized_scope(Client, type: :relation).order(:name),
      selectable_projects: authorized_scope(Project, type: :relation).order(:name),
      selectable_tasks: authorized_scope(Task, type: :relation).order(:name),
      selectable_users: authorized_scope(User, type: :relation).order(:last_name),
    )

    unless @filter.client_ids.blank?
      @form_data.selectable_projects = authorized_scope(Project, type: :relation).joins(:client)
                                              .where(client: { id: @filter.client_ids })
                                              .distinct.order(:name)
    end

    unless @filter.project_ids.blank?
      @form_data.selectable_tasks = authorized_scope(Task, type: :relation).joins(:projects)
                                        .where(projects: { id: @filter.project_ids })
                                        .distinct.order(:name)
      @form_data.selectable_users = authorized_scope(User, type: :relation).joins(:projects)
                                        .where(projects: { id: @filter.project_ids })
                                        .distinct.ordered_by_name
    end
  end
end
