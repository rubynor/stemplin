require "test_helper"

class ProjectShareTest < ActiveSupport::TestCase
  def setup
    @organization_one = organizations(:organization_one)
    @organization_two = organizations(:organization_two)
    @organization_three = organizations(:organization_three)
    @project = projects(:project_1)
  end

  test "valid project share" do
    project_share = ProjectShare.new(project: @project, organization: @organization_three, rate: 250)
    assert project_share.valid?
  end

  test "validates uniqueness of organization scoped to project" do
    # Fixture already creates project_1 shared with organization_two
    duplicate = ProjectShare.new(project: @project, organization: @organization_two, rate: 0)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:organization_id], "has already been taken"
  end

  test "validates that organization cannot be the project owning organization" do
    project_share = ProjectShare.new(project: @project, organization: @organization_one)
    assert_not project_share.valid?
    assert project_share.errors.added?(:organization, :is_project_owner)
  end

  test "rate_currency getter converts hundredths to currency format" do
    project_share = ProjectShare.new(rate: 250)
    assert_equal "2,50", project_share.rate_currency
  end

  test "rate_currency setter converts currency format to hundredths" do
    project_share = ProjectShare.new
    project_share.rate_currency = "2,50"
    assert_equal 250, project_share.rate
  end

  test "rate defaults to 0" do
    project_share = ProjectShare.new(project: @project, organization: @organization_three)
    assert_equal 0, project_share.rate
  end
end
