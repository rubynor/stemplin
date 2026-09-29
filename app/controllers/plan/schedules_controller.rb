module Plan
  class SchedulesController < BaseController
    MAX_RANGE_DAYS = 400

    def show
      authorize! with: Plan::SchedulePolicy
      @flags = frontend_flags
    end

    def data
      authorize! to: :show?, with: Plan::SchedulePolicy
      range = requested_range
      return render json: { errors: [ I18n.t("plan.errors.invalid_range") ] }, status: :bad_request unless range

      render json: Plan::ScheduleData.new(
        organization: current_organization,
        current_user: current_user,
        can_edit: allowed_to?(:manage?, with: Plan::SchedulePolicy),
        range: range,
        assignments: authorized_scope(Plan::Assignment.all, type: :relation),
        milestones: authorized_scope(Plan::Milestone.all, type: :relation),
        placeholders: authorized_scope(Plan::Placeholder.all, type: :relation),
        people: authorized_scope(AccessInfo.all, type: :relation, with: Plan::PersonPolicy),
        projects: visible_projects,
        time_regs: authorized_scope(TimeReg.all, type: :relation)
      )
    end

    private

    # Projects the user may see, plus any project they are booked on themselves:
    # someone scheduled on a project needs its name even without time-tracking
    # access to it.
    def visible_projects
      accessible = authorized_scope(Project.all, type: :relation).select(:id)
      booked = authorized_scope(Plan::Assignment.all, type: :relation).where(user_id: current_user.id).select(:project_id)
      Project.where(id: accessible).or(Project.where(id: booked))
    end

    # Everything the Elm app needs before its first request.
    def frontend_flags
      {
        basePath: plan_schedule_path,
        csrfToken: form_authenticity_token,
        page: params[:view].presence || "projects",
        date: params[:date].presence,
        zoom: params[:zoom].presence || "day",
        today: Date.current.iso8601,
        viewportWidth: 1280,
        links: {
          newProject: workspace_projects_path,
          invite: invite_users_workspace_team_members_path
        },
        i18n: {
          strings: flatten_translations(I18n.t("plan.ui")),
          months: I18n.t("date.abbr_month_names").compact,
          # Rails lists Sunday first; the plan's weeks start on Monday.
          weekdays: I18n.t("date.abbr_day_names").rotate(1)
        }
      }
    end

    def flatten_translations(hash, prefix = nil)
      hash.each_with_object({}) do |(key, value), flat|
        name = [ prefix, key ].compact.join(".")
        if value.is_a?(Hash)
          flat.merge!(flatten_translations(value, name))
        else
          flat[name] = value.to_s
        end
      end
    end

    def requested_range
      start_date = parse_date(params[:start])
      end_date = parse_date(params[:end])
      return unless start_date && end_date && start_date <= end_date
      return if (end_date - start_date).to_i > MAX_RANGE_DAYS

      start_date..end_date
    end
  end
end
