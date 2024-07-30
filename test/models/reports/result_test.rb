require "test_helper"

module Reports
  class ResultTest < ActiveSupport::TestCase
    def setup
      generate_dummy_data

      @filter_class = Reports::Filter
      @time_regs = [ @time_reg1, @time_reg2, @time_reg3, @time_reg4, @time_reg5, @time_reg6, @time_reg7, @time_reg8, @time_reg9, @time_reg10, @time_reg11, @time_reg12, @time_reg13, @time_reg14, @time_reg15, @time_reg16 ]
    end

    def filter_with(params = {})
      @filter_class.new(params)
    end

    test "should group time_regs by clients" do
      @filter = filter_with(category: @filter_class::CLIENTS)
      result = Reports::Result.new(time_regs: @time_regs, filter: @filter)

      expected_data = generate_expected_data(attribute: @filter_class::CLIENTS)
      assert_equal expected_data, result.grouped
    end

    test "should group time_regs by projects" do
      @filter = filter_with(category: @filter_class::PROJECTS)
      result = Reports::Result.new(time_regs: @time_regs, filter: @filter)

      expected_data = generate_expected_data(attribute: @filter_class::PROJECTS)
      assert_equal expected_data, result.grouped
    end

    test "should group time_regs by users" do
      @filter = filter_with(category: @filter_class::USERS)
      result = Reports::Result.new(time_regs: @time_regs, filter: @filter)

      expected_data = generate_expected_data(attribute: @filter_class::USERS)
      assert_equal expected_data, result.grouped
    end

    test "should group time_regs by tasks" do
      @filter = filter_with(category: @filter_class::TASKS)
      result = Reports::Result.new(time_regs: @time_regs, filter: @filter)

      expected_data = generate_expected_data(attribute: @filter_class::TASKS)
      assert_equal expected_data, result.grouped
    end

    private

    def generate_expected_data(attribute:, attribute_name_method: :name)
      singular_attribute = attribute.singularize.to_sym
      grouped_time_regs = @time_regs.group_by(&singular_attribute)
      grouped_time_regs.map do |group, time_regs|
        billable_time_regs = time_regs.select { |time_reg| time_reg.project.billable }
        total_minutes = time_regs.sum(&:minutes)
        total_billable_minutes = billable_time_regs.sum(&:minutes)
        total_billable_amount = ConvertKroneOre.out(billable_time_regs.sum(&:billed_amount))
        total_billable_minutes_percentage = (total_billable_minutes / total_minutes.to_f * 100).truncate(2)

        {
          attribute_name: group.send(attribute_name_method),
          total_minutes: total_minutes,
          total_billable_minutes: total_billable_minutes,
          total_billable_amount: total_billable_amount,
          total_billable_minutes_percentage: total_billable_minutes_percentage,
          group_link: { "#{singular_attribute}_ids": [ group.id ], category: nil }
        }
      end
    end

    def generate_dummy_data
      # Organization
      @organization = Organization.create!(name: "My report test organization", currency: "DKK")

      # User
      @user1 = User.create!(first_name: "User1", last_name: "User1", email: "user1@gmail.com", password: "password")
      @user2 = User.create!(first_name: "User2", last_name: "User2", email: "user2@gmail.com", password: "password")

      # AccessInfo
      AccessInfo.create!(user: @user1, organization: @organization, role: 1)
      AccessInfo.create!(user: @user2, organization: @organization, role: 0)

      # Clients
      @client1 = Client.create!(name: "Client1", organization: @organization)
      @client2 = Client.create!(name: "Client2", organization: @organization)

      # Tasks
      @task1 = Task.create!(name: "Task1", organization: @organization)
      @task2 = Task.create!(name: "Task2", organization: @organization)
      @task_3 = Task.create!(name: "Task3", organization: @organization)
      @task_4 = Task.create!(name: "Task4", organization: @organization)

      # Create Projects without validation (because of circular dependency)
      @project1 = Project.new(name: "Project1", client: @client1, rate: 150, billable: true)
      @project2 = Project.new(name: "Project2", client: @client1, rate: 200, billable: false)
      @project3 = Project.new(name: "Project3", client: @client2, rate: 250, billable: true)
      @project4 = Project.new(name: "Project4", client: @client2, rate: 300, billable: true)

      # Create AssignedTasks without validation (because of circular dependency)
      @assigned_task1 = AssignedTask.new(task: @task1, project: @project1)
      @assigned_task2 = AssignedTask.new(task: @task2, project: @project2)
      @assigned_task3 = AssignedTask.new(task: @task_3, project: @project3)
      @assigned_task4 = AssignedTask.new(task: @task_4, project: @project4)
      @assigned_task5 = AssignedTask.new(task: @task2, project: @project1, rate: 243)
      @assigned_task6 = AssignedTask.new(task: @task_4, project: @project3, rate: 300)
      @assigned_task7 = AssignedTask.new(task: @task_4, project: @project2, rate: 100)

      # Save Projects without validation
      @project1.save!(validate: false)
      @project2.save!(validate: false)
      @project3.save!(validate: false)
      @project4.save!(validate: false)

      # Save AssignedTasks without validation
      @assigned_task1.save!(validate: false)
      @assigned_task2.save!(validate: false)
      @assigned_task3.save!(validate: false)
      @assigned_task4.save!(validate: false)
      @assigned_task5.save!(validate: false)
      @assigned_task6.save!(validate: false)
      @assigned_task7.save!(validate: false)

      # Validate Projects and AssignedTasks separately
      [ @project1, @project2, @project3, @project4 ].each do |project|
        project.validate!
      end

      [ @assigned_task1, @assigned_task2, @assigned_task3, @assigned_task4, @assigned_task5, @assigned_task6, @assigned_task7 ].each do |assigned_task|
        assigned_task.validate!
      end

      # TimeRegs
      @time_reg1 = TimeReg.create!(user: @user1, assigned_task: @assigned_task1, minutes: 60, date_worked: Date.today - 1)
      @time_reg2 = TimeReg.create!(user: @user1, assigned_task: @assigned_task2, minutes: 120, date_worked: Date.today - 2)
      @time_reg3 = TimeReg.create!(user: @user1, assigned_task: @assigned_task3, minutes: 180, date_worked: Date.today - 3)
      @time_reg4 = TimeReg.create!(user: @user1, assigned_task: @assigned_task4, minutes: 240, date_worked: Date.today - 4)
      @time_reg5 = TimeReg.create!(user: @user1, assigned_task: @assigned_task5, minutes: 300, date_worked: Date.today - 5)
      @time_reg6 = TimeReg.create!(user: @user1, assigned_task: @assigned_task6, minutes: 360, date_worked: Date.today - 6)
      @time_reg7 = TimeReg.create!(user: @user1, assigned_task: @assigned_task7, minutes: 420, date_worked: Date.today - 7)
      @time_reg8 = TimeReg.create!(user: @user1, assigned_task: @assigned_task1, minutes: 480, date_worked: Date.today - 8)
      # User two time_regs
      @time_reg9 = TimeReg.create!(user: @user2, assigned_task: @assigned_task1, minutes: 60, date_worked: Date.today - 1)
      @time_reg10 = TimeReg.create!(user: @user2, assigned_task: @assigned_task2, minutes: 120, date_worked: Date.today - 2)
      @time_reg11 = TimeReg.create!(user: @user2, assigned_task: @assigned_task3, minutes: 180, date_worked: Date.today - 3)
      @time_reg12 = TimeReg.create!(user: @user2, assigned_task: @assigned_task4, minutes: 240, date_worked: Date.today - 4)
      @time_reg13 = TimeReg.create!(user: @user2, assigned_task: @assigned_task5, minutes: 300, date_worked: Date.today - 5)
      @time_reg14 = TimeReg.create!(user: @user2, assigned_task: @assigned_task6, minutes: 360, date_worked: Date.today - 6)
      @time_reg15 = TimeReg.create!(user: @user2, assigned_task: @assigned_task7, minutes: 420, date_worked: Date.today - 7)
      @time_reg16 = TimeReg.create!(user: @user2, assigned_task: @assigned_task1, minutes: 480, date_worked: Date.today - 8)
    end
  end
end
