module Workspace
  class ClientsController < WorkspaceController
    before_action :set_client, only: %i[edit_modal update destroy delete_confirmation]

    def index
      @pagy, @clients = pagy authorized_scope(Client, type: :relation).all
      authorize!
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
          turbo_stream.append(:organization_clients, partial: "workspace/clients/client", locals: { client: @client }),
          turbo_stream.action(:remove_modal, :modal)
        ]
      else
        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/clients/form", locals: { client: @client })
      end
    end

    def edit_modal
    end

    def update
      if @client.update(client_params)
        render turbo_stream: [
          turbo_flash(type: :success, data: t("notice.client_was_successfully_updated")),
          turbo_stream.replace(dom_id(@client), partial: "workspace/clients/client", locals: { client: @client }),
          turbo_stream.action(:remove_modal, :modal)
        ]
      else
        render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/clients/form", locals: { client: @client })
      end
    end

    def destroy
      if @client.destroy
        render turbo_stream: [
          turbo_flash(type: :success, data: t("notice.client_was_successfully_deleted")),
          turbo_stream.remove(dom_id(@client)),
          turbo_stream.action(:remove_modal, :modal)
        ]
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
      authorize! @client
    end
  end
end
