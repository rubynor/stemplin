module Api
  module V1
    class TimersController < BaseController
      def update
        @time_reg = authorized_scope(TimeReg, type: :relation, as: :own).find(params[:time_reg_id])
        authorize! @time_reg, to: :toggle_active?
        @time_reg.toggle_active
        render "api/v1/time_regs/show"
      end
    end
  end
end
