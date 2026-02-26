module Api
  module V1
    class OrganizationsController < BaseController
      def index
        authorize!
        @organizations = current_user.organizations
      end

      def show
        @organization = current_user.organizations.find(params[:id])
        authorize! @organization
      end
    end
  end
end
