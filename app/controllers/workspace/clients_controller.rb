module Workspace
  class ClientsController < WorkspaceController
    before_action :set_client, only: %i[edit_modal update destroy]

    def show
      @client = authorized_scope(Client, type: :relation).find(params[:id])
      authorize! @client
    end

    def new_modal
      @client = authorized_scope(Client, type: :relation).new
      authorize! @client
    end

    def create
      @client = authorized_scope(Client, type: :relation).new(client_params)
      authorize! @client

      if @client.save
        current_page = extract_page_from_referrer || 1

        @pagy, @clients = pagy authorized_scope(Client, type: :relation).order(:name).includes(:projects),
                              items: 6, page: current_page

        render turbo_stream: [
          turbo_flash(type: :success, data: t("notice.client_was_successfully_created")),
          turbo_stream.replace(:clients_collection, partial: "workspace/projects/clients_table", locals: { clients: @clients }),
          turbo_stream.replace(:clients_pagination, partial: "shared/pagination", locals: {
            pagy: @pagy,
            path: workspace_projects_path
          }),
          turbo_stream.action(:remove_modal, :modal)
        ]
      else
        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/clients/form", locals: { client: @client })
      end
    end

    def edit_modal
      authorize! @client
    end

    def update
      authorize! @client
      if @client.update(client_params)
        render turbo_stream: [
          turbo_flash(type: :success, data: t("notice.client_was_successfully_updated")),
          turbo_stream.replace(dom_id(@client), partial: "workspace/projects/client", locals: { client: @client }),
          turbo_stream.replace("#{dom_id(@client)}_show", template: "workspace/clients/show", locals: { client: @client }),
          turbo_stream.action(:remove_modal, :modal)
        ]
      else
        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/clients/form", locals: { client: @client })
      end
    end

    def destroy
      authorize! @client
      if @client.discard
        flash[:success] = t("notice.client_was_successfully_deleted")
        redirect_to workspace_projects_path
      else
        render turbo_stream: turbo_flash(type: :error, data: "Unable to proceed, could not delete client.")
      end
    end

    private

    def client_params
      params.require(:client).permit(:name, :description)
    end

    def set_client
      @client = Client.find(params[:id])
    end

    def extract_page_from_referrer
      return nil unless request.referrer

      uri = URI.parse(request.referrer)
      query_params = Rack::Utils.parse_query(uri.query)
      query_params['page']&.to_i
    rescue URI::InvalidURIError
      nil
    end
  end
end