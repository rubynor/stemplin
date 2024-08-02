require "test_helper"

class ConvertCurrencyHundredthsTest < ActiveSupport::TestCase
  test "#in converts text to currency (hundredths)" do
    assert_equal(ConvertCurrencyHundredths.in("100,50"), 10050)
  end

  test "#in converts currency as integer to hundredths" do
    assert_equal(1000, ConvertCurrencyHundredths.in(10))
  end

  test "#in converts currency as decimal to hundreths as integer" do
    assert_equal(150, ConvertCurrencyHundredths.in(1.5.to_d))

    assert(ConvertCurrencyHundredths.in(1.5.to_d).is_a?(Integer))
  end

  test "#in handles numbers with spaces in them" do
    assert_equal(1050, ConvertCurrencyHundredths.in("1 0,50"))
    assert_equal(100050, ConvertCurrencyHundredths.in("1 000,50"))
  end

  test "#out converts hundredths to currency as a formatted string" do
    assert_equal("100,50", ConvertCurrencyHundredths.out(10050))
  end
end
