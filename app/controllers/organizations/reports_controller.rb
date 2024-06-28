module Organizations
  class ReportsController < AuthenticatedController
    def index
      @filter = Organizations::Reports::Filter.new(filter_params)
      @time_regs = authorized_scope(TimeReg, type: :relation).between_dates(@filter.start_date, @filter.end_date)
      @time_regs = filtered_collection(@time_regs)
      @summary = Organizations::Reports::Summary.new(
        time_regs: @time_regs,
      )
      @results = Organizations::Reports::Result.new(time_regs: @time_regs, filter: @filter)
      authorize!
    end

    private

    def filter_params
      params.fetch(:filter, {}).permit(:start_date, :end_date, :category, :time_frame, Organizations::Reports::Filter::FILTER_MAPPINGS.keys)
    end

    def filtered_collection(collection)
      Organizations::Reports::Filter::FILTER_MAPPINGS.each do |filter_key, scope_method|
        if @filter.send(filter_key).present?
          collection = collection.send(scope_method, @filter.send(filter_key))
        end
      end

      collection
    end
  end
end
