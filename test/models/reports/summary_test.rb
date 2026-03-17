require "test_helper"

module Reports
  class SummaryTest < ActiveSupport::TestCase
    def setup
      @time_regs = TimeReg.between_dates(1.week.ago, Date.today + 1.day)
      @summary = Reports::Summary.new(time_regs: @time_regs)
    end

    test "#total_billable_amount returns the sum of all billable time_regs" do
      assert_equal @time_regs.billable.sum(&:billed_amount), @summary.total_billable_amount
    end

    test "#total_billable_amount_currency returns the sum of all billable time_regs, converted back from hundredths to decimal number" do
      assert_equal ConvertCurrencyHundredths.out(@time_regs.billable.sum(&:billed_amount)), @summary.total_billable_amount_currency
    end

    test "#total_minutes returns the sum of all time_regs minutes" do
      assert_equal @time_regs.sum(&:minutes), @summary.total_minutes
    end

    test "#total_billable_minutes returns the sum of all billable time_regs minutes" do
      assert_equal @time_regs.billable.sum(&:minutes), @summary.total_billable_minutes
    end

    test "#total_non_billable_minutes returns the sum of all non-billable time_regs minutes" do
      assert_equal @summary.total_minutes - @summary.total_billable_minutes, @summary.total_non_billable_minutes
    end
  end

  class SummaryWithOrganizationTest < ActiveSupport::TestCase
    def setup
      # Owner organization
      @owner_org = Organization.create!(name: "Owner Org", currency: "USD")

      # Guest organization
      @guest_org = Organization.create!(name: "Guest Org", currency: "USD")

      # User
      @user = User.create!(first_name: "Test", last_name: "User", email: "summary_org_test@example.com", password: "password")
      AccessInfo.create!(user: @user, organization: @owner_org, role: 1)

      # Client and project
      @client = Client.create!(name: "Summary Org Client", organization: @owner_org)

      @project = Project.new(name: "Summary Org Project", client: @client, rate: 10000, billable: true)
      @task = Task.create!(name: "Summary Org Task", organization: @owner_org)
      @assigned_task = AssignedTask.new(task: @task, project: @project, rate: 0)
      @project.save!(validate: false)
      @assigned_task.save!(validate: false)

      # Create a ProjectShare with a different rate for the guest org
      @project_share = ProjectShare.create!(project: @project, organization: @guest_org, rate: 5000)

      # Time registrations
      @time_reg = TimeReg.create!(user: @user, assigned_task: @assigned_task, minutes: 60, date_worked: Date.today)

      @time_regs = TimeReg.where(id: @time_reg.id)
    end

    test "#total_billable_amount without organization uses default billed_amount" do
      summary = Reports::Summary.new(time_regs: @time_regs)

      # 60 minutes = 1 hour, rate = 10000 (project rate since assigned_task rate is 0)
      expected = @time_regs.billable.sum(&:billed_amount)
      assert_equal expected, summary.total_billable_amount
    end

    test "#total_billable_amount with organization uses billed_amount_for" do
      summary = Reports::Summary.new(time_regs: @time_regs, organization: @guest_org)

      # Guest org share rate = 5000, 1 hour * 5000 = 5000
      expected = @time_regs.billable.sum { |tr| tr.billed_amount_for(@guest_org) }
      assert_equal expected, summary.total_billable_amount
      # Verify it differs from the default
      default_amount = @time_regs.billable.sum(&:billed_amount)
      assert_not_equal default_amount, summary.total_billable_amount
    end

    test "#total_billable_amount_currency with organization uses org-context rates" do
      summary = Reports::Summary.new(time_regs: @time_regs, organization: @guest_org)

      expected = ConvertCurrencyHundredths.out(@time_regs.billable.sum { |tr| tr.billed_amount_for(@guest_org) })
      assert_equal expected, summary.total_billable_amount_currency
    end
  end
end
