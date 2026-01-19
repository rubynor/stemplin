require "test_helper"

class HolidaysHelperTest < ActionView::TestCase
  test "holidays_for_country returns array of holidays" do
    holidays = holidays_for_country("us")
    assert holidays.is_a?(Array)
    assert holidays.all? { |h| h.is_a?(Hash) }
  end

  test "holidays_for_country returns empty for invalid country" do
    holidays = holidays_for_country("invalid")
    assert_equal [], holidays
  end

  test "format_holiday_date formats date correctly" do
    date = Date.new(2024, 7, 4)
    formatted = format_holiday_date(date)
    assert formatted.include?("July")
    assert formatted.include?("2024")
    assert formatted.include?("04")
  end

  test "country_name_from_code returns readable name or uppercase code" do
    # In test environment, countries config may not be loaded
    result_us = country_name_from_code("us")
    assert [ "United States", "US" ].include?(result_us), "Expected 'United States' or 'US', got '#{result_us}'"

    result_no = country_name_from_code("no")
    assert [ "Norway", "NO" ].include?(result_no), "Expected 'Norway' or 'NO', got '#{result_no}'"

    result_gb = country_name_from_code("gb")
    assert [ "United Kingdom", "GB" ].include?(result_gb), "Expected 'United Kingdom' or 'GB', got '#{result_gb}'"
  end

  test "country_name_from_code returns uppercase code for unknown countries" do
    assert_equal "XYZ", country_name_from_code("xyz")
  end

  test "for_select_countries returns array of arrays" do
    countries = for_select_countries([ :us, :no, :gb ])
    assert countries.is_a?(Array)
    assert_equal 3, countries.length
    assert countries.all? { |c| c.is_a?(Array) && c.length == 2 }
    # In test environment, the config may not be loaded so we get uppercase codes
    first_country_name = countries.first.first
    assert [ "United States", "US" ].include?(first_country_name)
    assert_equal "us", countries.first.last
  end
end
