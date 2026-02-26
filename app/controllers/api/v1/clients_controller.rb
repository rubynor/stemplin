module Api
  module V1
    class ClientsController < BaseController
      before_action :set_client, only: %i[show update destroy]

      def index
        authorize!
        @clients = authorized_scope(Client, type: :relation).order(:name)
      end

      def show
        authorize! @client
      end

      def create
        @client = Client.new(client_params)
        @client.organization = current_user.current_organization
        authorize! @client
        @client.save!
        render :show, status: :created
      end

      def update
        authorize! @client
        @client.update!(client_params)
        render :show
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
    end
  end
end
