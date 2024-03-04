require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "#format_date returns string" do
    date = Date.new(2024, 3, 4)
    result = format_date(date)
    assert_equal "Monday, 04. Mar", result
  end
end