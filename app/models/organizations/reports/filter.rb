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
        TEAM_MEMBERS = "team_members"
      ].freeze
      TIME_FRAMES = [
        WEEK = "week",
        MONTH = "month",
        YEAR = "year",
        CUSTOM = "custom"
      ].freeze
      DEFAULT_DATE = Date.today

      attribute :start_date, :date
      attribute :end_date, :date
      attribute :category, :string, default: -> { CLIENTS }
      attribute :time_frame, :string, default: -> { WEEK }

      def initialize(attributes = {})
        super
        set_default_dates if start_date.nil? && end_date.nil?
      end

      def next_period
        case time_frame
        when WEEK
          update_week(1.week)
        when MONTH
          update_month(1.month)
        when YEAR
          update_year(1.year)
        else
          update_week(1.week)
        end
      end

      def previous_period
        case time_frame
        when WEEK
          update_week(-1.week)
        when MONTH
          update_month(-1.month)
        when YEAR
          update_year(-1.year)
        else
          update_week(-1.week)
        end
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

      def tabs
        CATEGORIES.map do |category|
          {
            value: category,
            label: I18n.t("organizations.reports_filter.tabs.#{category}")
          }
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

      def update_week(duration)
        new_end_date = end_date + duration
        { start_date: new_end_date.beginning_of_week, end_date: new_end_date.end_of_week }
      end

      def update_month(duration)
        new_end_date = end_date + duration
        { start_date: new_end_date.beginning_of_month, end_date: new_end_date.end_of_month }
      end

      def update_year(duration)
        new_end_date = end_date + duration
        { start_date: new_end_date.beginning_of_year, end_date: new_end_date.end_of_year }
      end
    end
  end
end
