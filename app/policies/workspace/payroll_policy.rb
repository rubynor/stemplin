module Workspace
  # The Payroll page itself needs only an admin; the controller redirects to the integrations page
  # when there is no Tripletex connection to show.
  class PayrollPolicy < WorkspacePolicy
    def show?
      user.organization_admin?
    end
  end
end
