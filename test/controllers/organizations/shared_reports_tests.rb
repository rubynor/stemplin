module Organizations
  module SharedReportsTests
    extend ActiveSupport::Concern
    included do
      setup :common_setup

      def common_setup
        @user = users(:joe)
        sign_in @user
      end

      test "should get" do
        assert_response :success
        assert_not_nil assigns(:filter)
      end

      test " should have default start_date and end_date" do
        assert_equal Date.today.beginning_of_week, assigns(:filter).start_date
        assert_equal Date.today.end_of_week, assigns(:filter).end_date
        assert_equal true, assigns(:filter).default_period?
        assert_equal true, assigns(:filter).valid_time_frame?
        assert_equal false, assigns(:filter).is_custom_time_frame?
      end

      test "should have the default tab/category selected" do
        assert_equal Organizations::Reports::Filter::CLIENTS, assigns(:filter).category
        assert_equal Organizations::Reports::Filter::CLIENTS, assigns(:filter).active_tab
      end

      test "should have the default time_frame selected" do
        assert_equal Organizations::Reports::Filter::WEEK, assigns(:filter).time_frame
      end

      test "should have attributes for filter set to nil by default" do
        assert_nil assigns(:filter).client_id
        assert_nil assigns(:filter).project_id
        assert_nil assigns(:filter).task_id
        assert_nil assigns(:filter).user_id
      end

      test "should be able to toggle next_period in this case by default next week" do
        end_date = Date.today.end_of_week
        new_date = end_date + 1.week
        next_period_range = { start_date: new_date.beginning_of_week, end_date: new_date.end_of_week }

        assert_equal next_period_range, assigns(:filter).next_period
      end

      test "should be able to toggle previous_period in this case by default previous week" do
        end_date = Date.today.end_of_week
        new_date = end_date - 1.week
        next_period_range = { start_date: new_date.beginning_of_week, end_date: new_date.end_of_week }

        assert_equal next_period_range, assigns(:filter).previous_period
      end
    end
  end
end
