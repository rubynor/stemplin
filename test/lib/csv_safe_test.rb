require "test_helper"

class CsvSafeTest < ActiveSupport::TestCase
  test "text that a spreadsheet would run as a formula is quoted" do
    assert_equal [ "'=1+1", "'+1", "'-1", "'@SUM(A1)", "'\tx" ], CsvSafe.row([ "=1+1", "+1", "-1", "@SUM(A1)", "\tx" ])
  end

  test "ordinary text, numbers, dates and blanks are left alone" do
    row = [ "Did some work", -5, 1.5, Date.new(2026, 1, 1), nil, "" ]
    assert_equal row, CsvSafe.row(row)
  end
end
