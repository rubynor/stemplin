module Plan
  class PlaceholdersController < BaseController
    def create
      placeholder = current_organization.plan_placeholders.new(placeholder_params)
      authorize! placeholder
      placeholder.save!
      render json: placeholder_json(placeholder), status: :created
    end

    def update
      placeholder = authorized_scope(Plan::Placeholder.all, type: :relation).find(params[:id])
      authorize! placeholder
      placeholder.update!(placeholder_params)
      render json: placeholder_json(placeholder)
    end

    def destroy
      placeholder = authorized_scope(Plan::Placeholder.all, type: :relation).find(params[:id])
      authorize! placeholder
      placeholder.destroy!
      head :no_content
    end

    private

    def placeholder_params
      params.require(:placeholder).permit(:name, :roles)
    end

    def placeholder_json(placeholder)
      { id: placeholder.id, name: placeholder.name, roles: placeholder.roles.to_s }
    end
  end
end
