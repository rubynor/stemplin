class ProjectPolicy < ApplicationPolicy
  %i[ show new edit update destroy import ].each do |action|
    define_method("#{action}?") { user.organization_admin? && user.current_organization == record.organization }
  end

  def create?
    user.organization_admin? && user.current_organization == record.organization
  end

  scope_for :relation, :own do |relation|
    organization = user.current_organization
    relation = relation.joins(client: :organization).where(organizations: organization)
    relation = relation.joins(:project_accesses).where(project_accesses: user.project_accesses) if user.project_restricted?(organization)
    relation.distinct
  end

  scope_for :relation do |relation|
    organization = user.current_organization
    relation = relation.joins(client: :organization).where(organizations: organization)
    relation = relation.joins(:project_accesses).where(project_accesses: user.project_accesses) if user.project_restricted?(organization)
    relation.distinct
  end
end
