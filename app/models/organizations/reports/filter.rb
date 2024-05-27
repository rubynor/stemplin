# TODO: split model into logical separate files sharing a comon filter base_class

module Organizations
  module Reports
    class Filter
      include ActiveModel::Model
      include ActiveModel::Attributes

      CATEGORIES = [
        CLIENTS = "clients",
        PROJECTS = "projects",
        TASKS = "tasks",
        USERS = "users"
      ].freeze

      CLIENT_TABS = [ PROJECTS, TASKS, USERS ].freeze
      PROJECT_TABS = [ TASKS, USERS ].freeze
      TASK_TABS = [ PROJECTS, USERS ].freeze
      USER_TABS = [ PROJECTS, TASKS ].freeze

      TIME_FRAMES = [
        WEEK = "week",
        MONTH = "month",
        YEAR = "year",
        CUSTOM = "custom"
      ].freeze

      FILTER_MAPPINGS = {
        project_id: :by_project,
        client_id: :by_client,
        task_id: :by_task,
        user_id: :by_user
      }

      DEFAULT_DATE = Date.today

      attribute :start_date, :date
      attribute :end_date, :date
      attribute :category, :string, default: -> { CLIENTS }
      attribute :time_frame, :string, default: -> { WEEK }
      attribute :client_id, :integer
      attribute :project_id, :integer
      attribute :task_id, :integer
      attribute :user_id, :integer

      def initialize(attributes = {})
        super
        set_default_dates if start_date.nil? && end_date.nil?
      end

      def selected_element_name
        return Client.find(client_id).name if client_id.present?
        return Project.find(project_id).name if project_id.present?
        return Task.find(task_id).name if task_id.present?
        return User.find(user_id).name if user_id.present?
        nil
      end

      def next_period
        update_period_by(1)
      end

      def previous_period
        update_period_by(-1)
      end

      def current_time_range
        { start_date: start_date, end_date: end_date }
      end

      def current_selection
        return { client_id: client_id } if client_id.present?
        return { project_id: project_id } if project_id.present?
        return { task_id: task_id } if task_id.present?
        return { user_id: user_id } if user_id.present?
        {}
      end

      # @Note: This is only checking if this the default period(week, month, year) respectively
      def default_period?
        case time_frame
        when WEEK
          default_week?
        when MONTH
          start_date == DEFAULT_DATE.beginning_of_month && end_date == DEFAULT_DATE.end_of_month
        when YEAR
          start_date == DEFAULT_DATE.beginning_of_year && end_date == DEFAULT_DATE.end_of_year
        else
          default_week?
        end
      end

      # @Note: This is checking if a time_range is a valid (week, month, year) respectively
      def valid_time_frame?
        case time_frame
        when WEEK
          start_date == end_date.beginning_of_week && end_date == end_date.end_of_week
        when MONTH
          start_date == end_date.beginning_of_month && end_date == end_date.end_of_month
        when YEAR
          start_date == end_date.beginning_of_year && end_date == end_date.end_of_year
        else
          false # Custom time frame will always be false
        end
      end

      def tabs
        case
        when client_id.present?
          generate_tabs(*CLIENT_TABS)
        when project_id.present?
          generate_tabs(*PROJECT_TABS)
        when task_id.present?
          generate_tabs(*TASK_TABS)
        when user_id.present?
          generate_tabs(*USER_TABS)
        else
          generate_tabs(*CATEGORIES)
        end
      end

      def possible_tabs_for(attribute_name)
        case attribute_name
        when CLIENTS
          CLIENT_TABS
        when PROJECTS
          PROJECT_TABS
        when TASKS
          TASK_TABS
        when USERS
          USER_TABS
        else
          []
        end
      end


      def time_frames
        TIME_FRAMES.map do |time_frame|
          {
            value: time_frame,
            label: I18n.t("organizations.reports_filter.time_frames.#{time_frame}")
          }
        end
      end

      def active_tab
        category
      end

      def is_custom_time_frame?
        time_frame == CUSTOM
      end

      def generate_tabs(*categories)
        categories.map do |category|
          { value: category, label: I18n.t("organizations.reports_filter.tabs.#{category}") }
        end
      end

      private

      def set_default_dates
        case time_frame
        when WEEK
          self.start_date = DEFAULT_DATE.beginning_of_week
          self.end_date = DEFAULT_DATE.end_of_week
        when MONTH
          self.start_date = DEFAULT_DATE.beginning_of_month
          self.end_date = DEFAULT_DATE.end_of_month
        when YEAR
          self.start_date = DEFAULT_DATE.beginning_of_year
          self.end_date = DEFAULT_DATE.end_of_year
        else
          self.start_date = DEFAULT_DATE.beginning_of_week
          self.end_date = DEFAULT_DATE.end_of_week
        end
      end

      def default_week?
        start_date == DEFAULT_DATE.beginning_of_week && end_date == DEFAULT_DATE.end_of_week
      end

      def update_period_by(multiplier)
        case time_frame
        when WEEK
          update_period(1.week * multiplier, :week)
        when MONTH
          update_period(1.month * multiplier, :month)
        when YEAR
          update_period(1.year * multiplier, :year)
        else
          update_period(1.week * multiplier, :week)
        end
      end

      def update_period(duration, period_type)
        new_end_date = end_date + duration
        case period_type
        when :week
          { start_date: new_end_date.beginning_of_week, end_date: new_end_date.end_of_week }
        when :month
          { start_date: new_end_date.beginning_of_month, end_date: new_end_date.end_of_month }
        when :year
          { start_date: new_end_date.beginning_of_year, end_date: new_end_date.end_of_year }
        else
          { start_date: new_end_date.beginning_of_week, end_date: new_end_date.end_of_week }
        end
      end
    end
  end
end
