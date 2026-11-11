module Workspace
  class ClientsController < WorkspaceController
    include SetCurrency

    before_action :set_client, only: %i[edit_modal update destroy]

    helper_method :tripletex_customers, :tripletex_customers_error

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
      render turbo_stream: [
        turbo_flash(type: :success, data: t("notice.client_was_successfully_created")),
        *clients_collection_streams,
        turbo_stream.action(:remove_modal, :modal)
      ]
    else
      render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/clients/form", locals: { client: @client })
    end
  end

  def destroy
    authorize! @client

    if @client.discard
      render turbo_stream: [
        turbo_flash(type: :success, data: t("notice.client_was_successfully_deleted")),
        *clients_collection_streams
      ]
    else
      render turbo_stream: turbo_flash(type: :error, data: "Unable to proceed, could not delete client.")
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



    private

    def clients_collection_streams
      load_clients_with_pagination
      [
        turbo_stream.replace(:clients_collection, partial: "workspace/projects/clients_table", locals: { clients: @clients }),
        turbo_stream.replace(:clients_pagination, partial: "shared/pagination", locals: {
          pagy: @pagy,
          path: workspace_projects_path
        }),
        turbo_stream.replace(:clients_count, partial: "workspace/projects/clients_count", locals: { pagy: @pagy })
      ]
    end

    def load_clients_with_pagination
      current_page = extract_page_from_referrer || 1
      @pagy, @clients = pagy authorized_scope(Client, type: :relation).order(:name).includes(projects: { listed_project_shares: :organization }),
        items: 6, page: current_page
    end

    def client_params
      params.require(:client).permit(:name, :description, :tripletex_customer_id)
    end

    # nil when the workspace isn't connected to Tripletex; cached briefly so the modal opens fast.
    def tripletex_customers
      return @tripletex_customers if defined?(@tripletex_customers)

      integration = current_user.current_organization.tripletex_integration
      @tripletex_customers = integration && Rails.cache.fetch([ "tripletex_customers", integration.id, integration.updated_at.to_i ], expires_in: 5.minutes) do
        integration.api.customers
      end
    rescue Tripletex::Error => e
      @tripletex_customers_error = e.message
      @tripletex_customers = []
    end

    def tripletex_customers_error
      tripletex_customers
      @tripletex_customers_error
    end

    def set_client
      @client = Client.find(params[:id])
    end

    def extract_page_from_referrer
      return nil unless request.referrer

      uri = URI.parse(request.referrer)
      query_params = Rack::Utils.parse_query(uri.query)
      query_params["page"]&.to_i
    rescue URI::InvalidURIError
      nil
    end
  end
end
