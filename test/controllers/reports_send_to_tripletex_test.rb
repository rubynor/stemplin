require "test_helper"

class ReportsSendToTripletexTest < ActionController::TestCase
  tests ReportsController

  setup do
    @admin = users(:organization_admin)
    @organization = @admin.current_organization
    @organization.create_tripletex_integration!(employee_token: "secret-token")
    clients(:e_corp).update!(tripletex_customer_id: 501)
    @api = FakeTripletexApi.install
    @filter = { start_date: 30.days.ago.to_date, end_date: Date.today }
    sign_in @admin
  end

  teardown { FakeTripletexApi.reset }

  test "creates orders for the filtered hours and goes back to the report" do
    post :send_to_tripletex, params: { filter: @filter, return_to: "detailed" }

    assert_redirected_to detailed_reports_path(filter: assigns(:filter).to_h)
    assert_equal 1, @api.orders.size
    assert_equal 501, @api.orders.first.dig(:customer, :id)
    assert TimeReg.invoiced.exists?
    assert_match "Tripletex", flash[:success][:title]
  end

  test "respects the report filter" do
    post :send_to_tripletex, params: { filter: @filter.merge(user_ids: [ users(:ron).id ]) }

    assert TimeReg.invoiced.any?
    assert TimeReg.invoiced.all? { |reg| reg.user == users(:ron) }
  end

  test "shows the button on both report pages" do
    get :index, params: { filter: @filter }
    assert_includes response.body, I18n.t("tripletex.reports.send")

    get :detailed, params: { filter: @filter }
    assert_includes response.body, I18n.t("tripletex.reports.send")
  end

  test "members cannot send" do
    sign_in users(:joe)

    post :send_to_tripletex, params: { filter: @filter }

    assert_empty @api.orders
    assert TimeReg.invoiced.none?
  end

  test "admins without a connection cannot send" do
    @organization.tripletex_integration.destroy!

    post :send_to_tripletex, params: { filter: @filter }

    assert_empty @api.orders
  end
end
