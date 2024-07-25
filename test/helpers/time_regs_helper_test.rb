require "test_helper"

class TimeRegsHelperTest < ActionView::TestCase
  def setup
    @new_time_reg = TimeReg.new
    @existing_time_reg = time_regs(:time_reg_1)
  end

  test "#active_text should return create for new time_reg" do
    assert_equal t("common.create_time_reg"), active_text(@new_time_reg)
  end

  test "#active_text should return update for existing time_reg" do
    @existing_time_reg.update(minutes: 0)
    assert_equal t("common.update_time_reg"), active_text(@existing_time_reg)
  end
end
