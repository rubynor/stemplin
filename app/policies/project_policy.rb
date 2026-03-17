class ProjectPolicy < ApplicationPolicy
  def index?
    user.organization_admin?
  end

  %i[ show new edit update destroy import ].each do |action|
    define_method("#{action}?") { user.organization_admin? && user.current_organization == record.organization }
  end

  def create?
    user.organization_admin? && user.current_organization == record.organization
  end

  def invite_external_user?
    user.organization_admin? && user.current_organization == record.organization
  end

  scope_for :relation, :own do |relation|
    organization = user.current_organization

    own_ids = relation.joins(client: :organization)
                      .where(organizations: { id: organization.id })
                      .select(:id)
    shared_ids = relation.joins(:project_shares)
                         .where(project_shares: { organization_id: organization.id })
                         .select(:id)
    combined = relation.where(id: own_ids).or(relation.where(id: shared_ids))

    unless user.organization_admin?
      combined = combined.where(
        id: ProjectAccess.where(access_info: user.access_info(organization))
                         .select(:project_id)
      ) if user.project_restricted?(organization)
    end

    combined.distinct
  end

  scope_for :relation do |relation|
    organization = user.current_organization

    own_ids = relation.joins(client: :organization)
                      .where(organizations: { id: organization.id })
                      .select(:id)
    shared_ids = relation.joins(:project_shares)
                         .where(project_shares: { organization_id: organization.id })
                         .select(:id)
    combined = relation.where(id: own_ids).or(relation.where(id: shared_ids))

    unless user.organization_admin?
      combined = combined.where(
        id: ProjectAccess.where(access_info: user.access_info(organization))
                         .select(:project_id)
      ) if user.project_restricted?(organization)
    end

    combined.distinct
  end
end
