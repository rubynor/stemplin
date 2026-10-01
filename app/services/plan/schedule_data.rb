module Plan
  # Builds the JSON document the plan frontend renders for one date range.
  # All relations passed in must already be authorized-scoped by the caller.
  class ScheduleData
    def initialize(organization:, current_user:, can_edit:, range:, assignments:, milestones:, placeholders:, people:, projects:, time_regs:)
      @organization = organization
      @current_user = current_user
      @can_edit = can_edit
      @range = range
      @assignments = assignments
      @milestones = milestones
      @placeholders = placeholders
      @people = people
      @projects = projects
      @time_regs = time_regs
    end

    def as_json(*)
      projects = @projects.includes(:client).to_a
      {
        range: { start: @range.begin.iso8601, end: @range.end.iso8601 },
        today: Date.current.iso8601,
        canEdit: @can_edit,
        currentUserId: @current_user.id,
        defaultCapacityMinutes: @organization.plan_default_capacity_minutes,
        people: people_json,
        placeholders: @placeholders.order(:name).map { |placeholder| placeholder_json(placeholder) },
        clients: projects.map(&:client).uniq.sort_by { |client| client.name.downcase }.map { |client| { id: client.id, name: client.name } },
        projects: projects.sort_by { |project| [ project.client.name.downcase, project.name.downcase ] }.map { |project| project_json(project) },
        assignments: @assignments.overlapping(@range.begin, @range.end).order(:start_date, :id).map { |assignment| assignment_json(assignment) },
        milestones: @milestones.between_dates(@range.begin, @range.end).order(:date).map { |milestone| milestone_json(milestone) },
        actuals: actuals_json
      }
    end

    def self.assignment_json(assignment)
      {
        id: assignment.id,
        projectId: assignment.project_id,
        userId: assignment.user_id,
        placeholderId: assignment.placeholder_id,
        startDate: assignment.start_date.iso8601,
        endDate: assignment.end_date.iso8601,
        minutesPerDay: assignment.minutes_per_day,
        notes: assignment.notes.to_s
      }
    end

    private

    # Archived members and spectators only stay on the plan while they have
    # bookings in range, so past (and leftover future) work still shows who it
    # belonged to.
    def people_json
      booked = @assignments.overlapping(@range.begin, @range.end).select(:user_id)
      @people.unarchived.plannable.or(@people.where(user_id: booked)).includes(:user).to_a
        .reject { |access_info| access_info.user.nil? }
        .sort_by { |access_info| access_info.user.name.downcase }
        .map do |access_info|
          user = access_info.user
          {
            id: user.id,
            name: user.name.presence || user.email,
            email: user.email,
            role: access_info.role,
            capacityMinutes: access_info.plan_capacity_minutes,
            workDays: access_info.plan_work_days
          }
        end
    end

    def placeholder_json(placeholder)
      { id: placeholder.id, name: placeholder.name, roles: placeholder.roles.to_s }
    end

    def project_json(project)
      { id: project.id, name: project.name, clientId: project.client_id, color: Plan.color_for(project), billable: project.billable }
    end

    def assignment_json(assignment)
      self.class.assignment_json(assignment)
    end

    def milestone_json(milestone)
      { id: milestone.id, projectId: milestone.project_id, name: milestone.name, date: milestone.date.iso8601 }
    end

    # Tracked minutes per person, project and ISO week, so the frontend can put
    # what was planned next to what actually happened.
    def actuals_json
      # Re-wrap by id: the authorized scope is DISTINCT, and DISTINCT + SUM would
      # silently become SUM(DISTINCT minutes).
      TimeReg.where(id: @time_regs.select(:id))
        .between_dates(@range.begin, @range.end)
        .joins(:assigned_task)
        .group(:user_id, "assigned_tasks.project_id", Arel.sql("date_trunc('week', time_regs.date_worked)::date"))
        .sum(:minutes)
        .map do |(user_id, project_id, week), minutes|
          { userId: user_id, projectId: project_id, week: week.iso8601, minutes: minutes }
        end
    end
  end
end
