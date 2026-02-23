module Api
  module V1
    class ClientsController < BaseController
      before_action :set_client, only: %i[show update destroy]

      def index
        authorize! Client, to: :index?
        clients = authorized_scope(Client, type: :relation).order(:name)
        render json: clients.map { |client| client_json(client) }
      end

      def show
        authorize! @client
        render json: client_json(@client)
      end

      def create
        client = Client.new(client_params)
        client.organization = current_user.current_organization
        authorize! client
        client.save!
        render json: client_json(client), status: :created
      end

      def update
        authorize! @client
        @client.update!(client_params)
        render json: client_json(@client)
      end

      def destroy
        authorize! @client
        @client.discard!
        head :no_content
      end

      private

      def set_client
        @client = authorized_scope(Client, type: :relation).find(params[:id])
      end

      def client_params
        params.require(:client).permit(:name)
      end

      def client_json(client)
        {
          id: client.id,
          name: client.name,
          organization_id: client.organization_id,
          created_at: client.created_at,
          updated_at: client.updated_at
        }
      end
    end
  end
end
