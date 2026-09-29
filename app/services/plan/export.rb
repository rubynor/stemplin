require "csv"

module Plan
  # CSV of planned hours per row (project + person, or person + project) and
  # period (week or month), like Forecast's "Export scheduled hours".
  class Export
    VIEWS = %w[projects team].freeze
    PERIODS = %w[weekly monthly].freeze

    def initialize(assignments:, range:, view:, period:)
      @assignments = assignments.includes(:user, :placeholder, project: :client).overlapping(range.begin, range.end)
      @range = range
      @view = VIEWS.include?(view) ? view : VIEWS.first
      @period = PERIODS.include?(period) ? period : PERIODS.first
    end

    def filename
      "plan-#{@view}-#{@range.begin.iso8601}-#{@range.end.iso8601}.csv"
    end

    def to_csv
      buckets = periods
      rows = Hash.new { |hash, key| hash[key] = Array.new(buckets.size, 0) }

      @assignments.each do |assignment|
        key = row_key(assignment)
        buckets.each_with_index do |bucket, index|
          rows[key][index] += assignment.minutes_between(bucket.begin, bucket.end)
        end
      end

      CSV.generate do |csv|
        csv << header_labels + buckets.map { |bucket| bucket_label(bucket) } + [ I18n.t("plan.export.total") ]
        rows.sort_by { |key, _| key.map { |part| part.to_s.downcase } }.each do |key, minutes|
          next if minutes.sum.zero?

          csv << key + minutes.map { |value| hours(value) } + [ hours(minutes.sum) ]
        end
      end
    end

    private

    def header_labels
      client, project, person = %w[client project person].map { |key| I18n.t("plan.export.#{key}") }
      @view == "projects" ? [ client, project, person ] : [ person, client, project ]
    end

    def row_key(assignment)
      person = assignment.user&.name.presence || assignment.user&.email || assignment.placeholder&.name
      client = assignment.project&.client&.name.to_s
      project = assignment.project&.name || I18n.t("plan.time_off")
      @view == "projects" ? [ client, project, person ] : [ person, client, project ]
    end

    def periods
      if @period == "monthly"
        first = @range.begin.beginning_of_month
        months = []
        while first <= @range.end
          months << ([ first, @range.begin ].max..[ first.end_of_month, @range.end ].min)
          first = first.next_month
        end
        months
      else
        first = @range.begin.beginning_of_week
        weeks = []
        while first <= @range.end
          weeks << ([ first, @range.begin ].max..[ first.end_of_week, @range.end ].min)
          first += 1.week
        end
        weeks
      end
    end

    def bucket_label(bucket)
      @period == "monthly" ? bucket.begin.strftime("%Y-%m") : bucket.begin.beginning_of_week.iso8601
    end

    def hours(minutes)
      (minutes / 60.0).round(2)
    end
  end
end
