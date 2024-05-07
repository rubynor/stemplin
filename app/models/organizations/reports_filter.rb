module Organizations
  class ReportsFilter
    include ActiveModel::Model
    include ActiveModel::Attributes

    CATEGORIES = %w[clients projects tasks team_members].freeze
    DEFAULT_DATE = Date.today

    attribute :start_date, :date, default: -> { DEFAULT_DATE.beginning_of_week }
    attribute :end_date, :date, default: -> { DEFAULT_DATE.end_of_week }
    attribute :category, :string, default: -> { CATEGORIES.first }

    def next_week
      week_range(end_date + 1.week)
    end

    def previous_week
      week_range(end_date - 1.week)
    end

    def current_time_range
      { start_date: start_date, end_date: end_date }
    end

    def default_week?
      start_date == DEFAULT_DATE.beginning_of_week && end_date == DEFAULT_DATE.end_of_week
    end

    def valid_week?
      start_date == end_date.beginning_of_week && end_date == end_date.end_of_week
    end

    def tabs
      CATEGORIES.map do |category|
        {
          value: category,
          label: I18n.t("organizations.reports_filter.tabs.#{category}")
        }
      end
    end

    def active_tab
      category
    end

    private

    def week_range(given_date)
      { start_date: given_date.beginning_of_week, end_date: given_date.end_of_week }
    end
  end
end
