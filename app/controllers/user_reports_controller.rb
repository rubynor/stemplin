class UserReportsController < ReportsController
  GROUPES = { 'Client' => 'client', 'Project' => 'project', 'Task' => 'task', 'Date' => 'date' } # columns to group report by
  START_GROUP = 'date' # start date when creating a user report

  def show
    @report = UserReport.find(params[:id])
    @time_regs = get_time_regs(@report, @report.user_id, @report.project_ids, @report.task_ids)
    @grouped_report = group_time_regs(@time_regs, @report.group_by)
    @user = User.find(@report.user_id)

    # data for the edit form
    @show_edit_form = false
    @groupes = GROUPES
    @timeframeOptions = get_timeframe_options
    @users = User.all
    @grouped_projects = @users.find(@report.user_id).projects.group_by(&:client)
    @tasks = Task.joins(:assigned_tasks).where(assigned_tasks: { project_id: @report.project_ids }).distinct
    @show_custom_timeframe = @report.timeframe == 'custom'
  end

  def new
    # data for the new form
    @show_custom_timeframe = false
    @report = UserReport.new
    @timeframeOptions = get_timeframe_options
    @users = User.all
    @grouped_projects = []
    @tasks = []
  end

  def create
    @report = UserReport.new(user_report_params)

    @report.group_by = START_GROUP # sets standard group from a const
    set_dates(@report) unless @report.timeframe == 'custom' #  sets the correct dates

    # tries to save the report
    if @report.save
      redirect_to @report
    else
      # data for the new form incase of re-rendering
      @show_custom_timeframe = @report.timeframe == 'custom'
      @timeframeOptions = get_timeframe_options
      @users = User.all
      @grouped_projects = @report.user_id.present? ? User.find(@report.user_id).projects.group_by(&:client) : []
      @tasks = @report.project_ids.present? ? Task.joins(:assigned_tasks).where(assigned_tasks: { project_id: @report.project_ids }).distinct : []
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # data for the edit form
    @report = UserReport.find(params[:id])
    @timeframeOptions = get_timeframe_options
    @users = User.all
    @grouped_projects = @users.find(@report.user_id).projects.group_by(&:client)
    @tasks = Task.joins(:assigned_tasks).where(assigned_tasks: { project_id: @report.project_ids }).distinct
    @show_custom_timeframe = @report.timeframe == 'custom'
  end

  def update
    @report = UserReport.find(params[:id])

    # stores the old time_regs incase of re-rendering
    @time_regs = get_time_regs(@report, @report.user_id, @report.project_ids, @report.task_ids)
    @grouped_report = group_time_regs(@time_regs, @report.group_by)

    # clears data if invalid
    @report.project_ids = [] unless user_report_params[:user_id] == @report.user_id
    @report.task_ids = [] unless user_report_params[:project_ids].present?

    @report.assign_attributes(user_report_params)

    set_dates(@report) unless @report.timeframe == 'custom' # sets the correct dates

    # tries to save the changes
    if @report.save
      redirect_to @report
    else
      # data for the show page incase of re-rendering
      @show_edit_form = true
      @groupes = GROUPES
      @show_custom_timeframe = @report.timeframe == 'custom'
      @timeframeOptions = get_timeframe_options
      @users = User.all
      @grouped_projects = @report.user_id.present? ? User.find(@report.user_id).projects.group_by(&:client) : []
      @tasks = Task.joins(:assigned_tasks).where(assigned_tasks: { project_id: user_report_params[:project_ids] }).distinct
      render :show, status: :unprocessable_entity
    end
  end

  # changes the grouping of the report
  def update_group
    @report = UserReport.find(params[:user_report_id])

    # checks for valid new grouping
    if GROUPES.values.include?(params[:group_by])
      @report.group_by = params[:group_by]
      # tries to save the new changes
      if @report.save
        redirect_to @report
      else
        flash[:alert] = 'Could not change the grouping'
        redirect_to @report
      end
    else
      flash[:alert] = 'Invalid group'
      redirect_to @report
    end
  end

  # ********************
  # AJAX form updates *
  # *******************

  # updates the report form with projects from a specific user
  # returns a partial
  def update_projects_checkboxes
    grouped_projects = User.find(params[:user_id]).projects.group_by(&:client)
    render partial: 'projects', locals: { report: UserReport.new, grouped_projects: }
  end

  # updates the report form with tasks from specific projects
  # returns a partial
  def update_tasks_checkboxes
    @tasks = Task.joins(:assigned_tasks).where(assigned_tasks: { project_id: params[:project_ids] }).distinct
    render partial: 'tasks', locals: { report: UserReport.new, tasks: @tasks }
  end

  # permits only valid attributes
  private

  def user_report_params
    params.require(:user_report).permit(:timeframe, :date_start, :user_id, :date_end, project_ids: [], task_ids: [])
  end
end
