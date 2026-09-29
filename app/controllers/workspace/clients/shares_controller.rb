module Workspace
  module Clients
    # Shares several of a client's projects with one address in one go: one email, one answer.
    class SharesController < WorkspaceController
      include SetCurrency

      before_action :set_client

      def new_modal
        authorize! @client, to: :share?
        @selected_ids = @projects.map(&:id)
      end

      def create
        authorize! @client, to: :share?
        @email = params.dig(:project_share, :invited_email).to_s
        @selected_ids = Array(params.dig(:project_share, :project_ids)).map(&:to_i)
        shares = @projects.select { |project| @selected_ids.include?(project.id) }
          .map { |project| project.project_shares.new(invited_email: @email, invited_by: current_user) }
        shares.each { |share| authorize! share }

        @errors = share_errors(shares)
        if @errors.any?
          return render turbo_stream: turbo_stream.replace(:modal, partial: "workspace/clients/shares/form",
            locals: { client: @client, projects: @projects, selected_ids: @selected_ids, email: @email, errors: @errors })
        end

        ActiveRecord::Base.transaction { shares.each(&:save!) }
        UserMailer.project_share_invitation_email(project_shares: shares).deliver_later

        notice = shares.one? ? t("project_shares.notice.invited", email: shares.first.invited_email) : t("project_shares.notice.invited_many", count: shares.size, email: shares.first.invited_email)
        render turbo_stream: [
          turbo_flash(type: :success, data: notice),
          turbo_stream.replace(dom_id(@client), partial: "workspace/projects/client", locals: { client: clients_scope.find(@client.id) }),
          turbo_stream.action(:remove_modal, :modal)
        ]
      end

      private

      def set_client
        @client = clients_scope.find(params[:client_id])
        @projects = @client.projects.sort_by(&:name)
      end

      def clients_scope
        authorized_scope(Client, type: :relation).includes(projects: { listed_project_shares: :organization })
      end

      # The same problem on several projects is reported once, naming the projects it applies to.
      def share_errors(shares)
        return [ t("project_shares.client.none_selected") ] if shares.empty?

        shares.reject(&:valid?)
          .flat_map { |share| share.errors.full_messages.map { |message| [ message, share.project.name ] } }
          .group_by(&:first)
          .map { |message, pairs| pairs.size == shares.size ? message : "#{message} (#{pairs.map(&:last).to_sentence})" }
      end
    end
  end
end
