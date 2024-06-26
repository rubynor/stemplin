module Organizations
  class ReportsController < AuthenticatedController
    before_action :authorize!

    def index
      @filter = Organizations::Reports::Filter.new(filter_params)
      @time_regs = authorized_scope(TimeReg, type: :relation).between_dates(@filter.start_date, @filter.end_date)
      @time_regs = filtered_collection(@time_regs)
      @summary = Organizations::Reports::Summary.new(
        time_regs: @time_regs,
      )
      @results = Organizations::Reports::Result.new(time_regs: @time_regs, filter: @filter)
    end

    def detailed
      @filter = Organizations::Reports::Filter.new(filter_params)

      time_regs = authorized_scope(TimeReg, type: :relation).between_dates(@filter.start_date, @filter.end_date)

      time_regs = filtered_collection(time_regs)
      total_billable_minutes = time_regs.joins(:project).where(project: { billable: true }).sum(&:minutes)
      total_minutes = time_regs.sum(&:minutes)
      clients = authorized_scope(Client, type: :relation).joins(:time_regs).where(time_regs: { id: time_regs }).distinct
      projects = authorized_scope(Project, type: :relation).joins(:time_regs).where(time_regs: { id: time_regs }).distinct
      tasks = authorized_scope(Task, type: :relation).joins(:time_regs).where(time_regs: { id: time_regs }).distinct
      users = authorized_scope(User, type: :relation).joins(:time_regs).where(time_regs: { id: time_regs }).distinct

      @structured_report_data = time_regs.group_by { |reg| reg.date_worked }.sort_by { |key| key  }
      @detailed_report_data = OpenStruct.new(
        time_regs: time_regs,
        total_billable_minutes: total_billable_minutes,
        total_minutes: total_minutes,
        clients: clients,
        projects: projects,
        tasks: tasks,
        users: users,
      )

      # render "organizations/reports/detailed/show"
    end

    private

    def filter_params
      params.fetch(:filter, {}).permit(:start_date, :end_date, :category, :time_frame, Organizations::Reports::Filter::FILTER_MAPPINGS.keys)
    end

    def filtered_collection(collection)
      Organizations::Reports::Filter::FILTER_MAPPINGS.each do |filter_key, scope_method|
        if @filter.send(filter_key).present?
          collection = collection.send(scope_method, @filter.send(filter_key))
        end
      end

      collection
    end
  end
end
