class ProjectReportsController < ReportsController
  GROUPES = { "Task" => "task", "Date" => "date", "User" => "user" } # columns to group report by
  START_GROUP = "date" # standard grouping when creating new project report

  # show report
  def show
    @show_edit_form = false
    @report = ProjectReport.find(params[:id])
    @time_regs = get_time_regs(@report, @report.member_ids, @report.project_id, @report.task_ids)
    @grouped_report = group_time_regs(@time_regs, @report.group_by)
    @groupes = GROUPES
    @project = Project.find(@report.project_id)

    @structured_report_data = TimeRegsPresenter.new(@time_regs).report_data(
      title: @project.name,
      keys: [ :task, :user ]
    )

    # data for the edit form
    @timeframeOptions = get_timeframe_options
    @clients = Client.all
    @projects = @clients.find(@report.client_id).projects
    project = @projects.find(@report.project_id)
    @members = project.users
    @tasks = project.tasks
    @show_custom_timeframe = @report.timeframe == "custom"
  end

  def update
    @report = ProjectReport.find(params[:id])

    # saves old data to render every time_reg if needed
    @time_regs = get_time_regs(@report, @report.member_ids, @report.project_id, @report.task_ids)
    @grouped_report = group_time_regs(@time_regs, @report.group_by)

    # clear arrays if no new data
    @report.member_ids = [] unless project_report_params[:member_ids].present?
    @report.task_ids = [] unless project_report_params[:task_ids].present?

    @report.assign_attributes(project_report_params.except(:project_id))

    # only adds project_id if it is a valid project (avoids error if user tries to update with "select a project" value)
    @report.project_id = Project.exists?(project_report_params[:project_id]) ? project_report_params[:project_id] : nil

    # sets new dates
    set_dates(@report) unless @report.timeframe == "custom"

    # tries to update the report with new values
    if @report.save
      redirect_to @report
    else
      # sets all data the page needs when re-rendering with errors in the form
      @show_edit_form = true
      @groupes = GROUPES
      @show_custom_timeframe = @report.timeframe == "custom"
      @timeframeOptions = get_timeframe_options
      @clients = Client.all
      @projects = @report.client_id.present? ? @clients.find(@report.client_id).projects : []

      if @report.project_id.present?
        project = Project.find(@report.project_id)
        @members = @report.member_ids.present? ? project.users : []
        @tasks = @report.task_ids.present? ? project.tasks : []
      else
        @members = []
        @tasks = []
      end
      render :show, status: :unprocessable_entity
    end
  end

  def new
    # data for the new form
    @report = ProjectReport.new
    @show_custom_timeframe = false
    @timeframeOptions = get_timeframe_options
    @clients = Client.all
    @projects = []
    @members = []
    @tasks = []
  end

  def create
    # creates a new report and sets values from form
    @report = ProjectReport.new(project_report_params)
    set_dates(@report) unless @report.timeframe == "custom"
    @report.group_by = START_GROUP # standard grouping from const

    # tries to save the new report
    if @report.save
      redirect_to @report
    else
      # else: re-renders the new-form with errors
      @show_custom_timeframe = @report.timeframe == "custom"
      @timeframeOptions = get_timeframe_options
      @clients = Client.all
      @projects = @report.client_id.present? ? Project.where(client_id: @report.client_id) : []
      if @report.project_id.present?
        project = Project.find(@report.project_id)
        @members = @report.member_ids.present? ? project.users : []
        @tasks = @report.task_ids.present? ? project.tasks : []
      else
        @members = []
        @tasks = []
      end
      render :new, status: :unprocessable_entity
    end
  end

  def update_group
    @report = ProjectReport.find(params[:project_report_id])

    # checks for valid grouping
    if GROUPES.values.include?(params[:group_by])
      @report.group_by = params[:group_by]

      # tries to update the grouping
      if @report.save
        redirect_to @report
      else
        flash[:alert] = t("alert.could_not_change_the_grouping")
        redirect_to @report
      end
    else
      flash[:alert] = t("alert.invalid_group")
      redirect_to @report
    end
  end

  def update_projects_select
    projects = Project.where(client_id: params[:client_id])
    project_options = select_options(projects, :name)
    report = get_report

    if turbo_frame_request?
      render partial: "project_reports/projects_select", locals: { report: report, options: project_options }
    end
  end

  def update_members_checkboxes
    members = get_project_members
    report = get_report

    if turbo_frame_request?
      render partial: "project_reports/members_checkboxes",
             locals: { report: report, collection: members, text: "member" }
    end
  end

  def update_tasks_checkboxes
    tasks = get_project_tasks
    report = get_report

    if turbo_frame_request?
      render partial: "project_reports/tasks_checkboxes",
             locals: { report: report, collection: tasks, text: "task" }
    end
  end

  def detailed
    @report = ProjectReport.find(params[:id])
    @time_regs = get_time_regs(@report, @report.member_ids, @report.project_id, @report.task_ids)
    @structured_report_data = @time_regs.group_by { |reg| reg[:date_worked] }.sort_by { |key| key  }

    @client = Client.find(@report.client_id)
    @project = Project.find(@report.project_id)
    @total_billable_minutes = @project.billable_project ? @time_regs.sum(&:minutes) : 0
    @total_minutes = @time_regs.sum(&:minutes)
    @users = User.where(id: @report.member_ids)
  end

  private

  def select_options(collection, attribute)
    collection.map { |item| [ item.send(attribute), item.id ] }
  end

  def get_project_members
    params[:project_id] ? Project.find(params[:project_id]).users : []
  end

  def get_project_tasks
    params[:project_id] ? Project.find(params[:project_id]).tasks : []
  end

  def get_report
    params[:project_report_id] ? ProjectReport.find(params[:project_report_id]) : ProjectReport.new
  end

  def project_report_params
    params.require(:project_report).permit(:timeframe, :date_start, :date_end, :client_id, :project_id, member_ids: [],
                                                                                                        task_ids: [])
  end
end
