module Api
  module V1
    class OrganizationsController < BaseController
      def index
        organizations = current_user.organizations
        render json: organizations.map { |org| organization_json(org) }
      end

      def show
        organization = current_user.organizations.find(params[:id])
        render json: organization_json(organization)
      end

      private

      def organization_json(organization)
        {
          id: organization.id,
          name: organization.name,
          currency: organization.currency,
          created_at: organization.created_at,
          updated_at: organization.updated_at
        }
      end
    end
  end
end
