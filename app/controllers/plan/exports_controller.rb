module Plan
  class ExportsController < BaseController
    def show
      authorize! to: :export?, with: Plan::SchedulePolicy
      start_date = parse_date(params[:start])
      end_date = parse_date(params[:end])
      unless start_date && end_date && start_date <= end_date && (end_date - start_date).to_i <= 400
        return render json: { errors: [ I18n.t("plan.errors.invalid_range") ] }, status: :bad_request
      end

      export = Plan::Export.new(
        assignments: authorized_scope(Plan::Assignment.all, type: :relation),
        range: start_date..end_date,
        view: params[:view],
        period: params[:period]
      )
      send_data export.to_csv, filename: export.filename, type: "text/csv"
    end
  end
end
