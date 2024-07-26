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

      ALL_TABS = [ CLIENTS, PROJECTS, TASKS, USERS ].freeze
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
        project_ids: :by_projects,
        client_ids: :by_clients,
        task_ids: :by_tasks,
        user_ids: :by_users
      }

      DEFAULT_DATE = Date.today

      attribute :start_date, :date
      attribute :end_date, :date
      attribute :category, :string
      attribute :time_frame, :string, default: -> { MONTH }
      attribute :client_ids, array: true
      attribute :project_ids, array: true
      attribute :task_ids, array: true
      attribute :user_ids, array: true

      def initialize(attributes = {})
        super
        set_default_dates if start_date.nil? && end_date.nil?
        self.category = visible_tabs.first if category.blank?
      end

      def selected_elements_names
        res = {}
        res[CLIENTS] = Client.where(id: client_ids).pluck(:name) unless client_ids.blank?
        res[PROJECTS] = Project.where(id: project_ids).pluck(:name) unless project_ids.blank?
        res[TASKS] = Task.where(id: task_ids).pluck(:name) unless task_ids.blank?
        res[USERS] = User.where(id: user_ids).to_a.map { |user| user.name } unless user_ids.blank?
        res
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

      def visible_tabs
        vis_tabs = ALL_TABS
        vis_tabs &= CLIENT_TABS unless client_ids.blank?
        vis_tabs &= PROJECT_TABS unless project_ids.blank?
        vis_tabs &= TASK_TABS unless task_ids.blank?
        vis_tabs &= USER_TABS unless user_ids.blank?
        vis_tabs
      end

      def tabs
        generate_tabs(*visible_tabs)
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

      def to_h(**properties)
        properties.reverse_merge(
          start_date: start_date,
          end_date: end_date,
          category: category,
          time_frame: time_frame,
          client_ids: client_ids,
          project_ids: project_ids,
          task_ids: task_ids,
          user_ids: user_ids
        ).compact
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
