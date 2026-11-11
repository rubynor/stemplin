require "test_helper"

module Tripletex
  class CreateOrdersTest < ActiveSupport::TestCase
    setup do
      @organization = organizations(:organization_one)
      @client = clients(:e_corp)
      @client.update!(tripletex_customer_id: 501)
      @api = FakeTripletexApi.new
    end

    def call(time_regs = TimeReg.all)
      CreateOrders.new(organization: @organization, time_regs: time_regs, api: @api).call
    end

    test "creates one order per client with a line per project and task" do
      expected = CreateOrders.invoiceable(TimeReg.all, @organization).to_a
      assert expected.any?

      result = call

      assert_equal 1, @api.orders.size
      order = @api.orders.first
      assert_equal({ id: 501 }, order[:customer])
      assert_equal expected.map(&:assigned_task_id).uniq.size, order[:orderLines].size
      assert_in_delta expected.sum(&:minutes) / 60.0, order[:orderLines].sum { |line| line[:count] }, 0.01
      assert_equal expected.map { |reg| reg.used_rate / 100.0 }.uniq.sort, order[:orderLines].map { |line| line[:unitPriceExcludingVatCurrency] }.uniq.sort
      assert_equal expected.sum(&:minutes), result.minutes
      assert_empty result.errors
    end

    test "marks sent hours as invoiced with the order id and skips them next time" do
      call
      sent = TimeReg.invoiced.to_a

      assert sent.any?
      assert sent.all? { |reg| reg.tripletex_order_id == 1001 }

      result = call
      assert_equal 1, @api.orders.size
      assert_empty result.orders
    end

    test "only sends billable, finished time" do
      expected = CreateOrders.invoiceable(TimeReg.all, @organization).ids

      call

      assert_equal expected.sort, TimeReg.invoiced.ids.sort
      assert TimeReg.invoiced.joins(:project).where(projects: { billable: false }).none?
      assert TimeReg.invoiced.where.not(start_time: nil).none?
    end

    test "skips clients that are not linked to a Tripletex customer" do
      @client.update!(tripletex_customer_id: nil)

      result = call

      assert_empty @api.orders
      assert_includes result.skipped_clients, @client
      assert TimeReg.invoiced.none?
    end

    test "never sends time on other organizations' clients" do
      clients(:f_corp).update!(tripletex_customer_id: 777)

      call

      assert @api.orders.none? { |order| order[:customer][:id] == 777 }
    end

    test "leaves hours uninvoiced when Tripletex rejects the order" do
      @api = FakeTripletexApi.new(error: "Tripletex: kunden finnes ikke")

      result = call

      assert_equal [ "E Corp: Tripletex: kunden finnes ikke" ], result.errors
      assert TimeReg.invoiced.none?
    end

    test "refuses to run without a connection" do
      assert_raises(Tripletex::Error) do
        CreateOrders.new(organization: @organization, time_regs: TimeReg.all).call
      end
    end
  end
end
