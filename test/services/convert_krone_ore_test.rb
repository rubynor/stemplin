require "test_helper"

class ConvertKroneOreTest < ActiveSupport::TestCase
  test "#in converts text to currency (øre)" do
    assert_equal(ConvertKroneOre.in("100,50"), 10050)
  end

  test "#in converts kroner as integer to øre" do
    assert_equal(1000, ConvertKroneOre.in(10))
  end

  test "#in converts kroner as decimal to øre as integer" do
    assert_equal(150, ConvertKroneOre.in(1.5.to_d))

    assert(ConvertKroneOre.in(1.5.to_d).is_a?(Integer))
  end

  test "#in handles numbers with spaces in them" do
    assert_equal(1050, ConvertKroneOre.in("1 0,50"))
    assert_equal(100050, ConvertKroneOre.in("1 000,50"))
  end

  test "#out converts øre to kroner as a formatted string" do
    assert_equal("100,50", ConvertKroneOre.out(10050))
  end
end
