# Stands in for Tripletex::Client in tests. Install it with `FakeTripletexApi.install(fake)`;
# every TripletexIntegration#api then returns it until `FakeTripletexApi.reset`.
#
# pay_details is keyed by employee id; ids it does not hold come back as nil (no employment).
# run_error / line_error / delete_error take an exception instance that the matching call raises.
class FakeTripletexApi
  module Hook
    def api = FakeTripletexApi.current || super
  end

  class << self
    attr_accessor :current

    def install(fake = new) = self.current = fake
    def reset = self.current = nil
  end

  attr_reader :salary_runs, :salary_lines, :deleted_runs

  def initialize(company: { "id" => 42, "name" => "Firma AS" }, error: nil, employees: [], pay_details: {}, salary_types: [],
                 run_error: nil, line_error: nil, delete_error: nil)
    @company = company
    @error = error
    @employees = employees
    @pay_details = pay_details
    @salary_types = salary_types
    @run_error = run_error
    @line_error = line_error
    @delete_error = delete_error
    @salary_runs = []
    @salary_lines = []
    @deleted_runs = []
  end

  def company
    raise Tripletex::Error, @error if @error
    @company
  end

  def employees = @employees

  def pay_details(employee_ids, on:)
    employee_ids.index_with { |id| @pay_details[id] }
  end

  def salary_types = @salary_types

  def create_salary_run(employee_id:, year:, month:, date:, description:)
    raise @run_error if @run_error

    ids = { "transaction_id" => 5001 + @salary_runs.size, "payslip_id" => 9001 + @salary_runs.size }
    @salary_runs << ids.merge("employee_id" => employee_id, "year" => year, "month" => month, "date" => date, "description" => description)
    ids
  end

  def add_salary_line(transaction_id:, payslip_id:, salary_type_id:, rate:, count:)
    raise @line_error if @line_error

    @salary_lines << { "transaction_id" => transaction_id, "payslip_id" => payslip_id, "salary_type_id" => salary_type_id, "rate" => rate, "count" => count }
    nil
  end

  def delete_salary_run(transaction_id)
    raise @delete_error if @delete_error

    @deleted_runs << transaction_id
    nil
  end
end

TripletexIntegration.prepend(FakeTripletexApi::Hook)
