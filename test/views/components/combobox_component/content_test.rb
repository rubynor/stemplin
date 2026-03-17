# frozen_string_literal: true

require "test_helper"

module ComboboxComponent
  class ContentTest < ActiveSupport::TestCase
    test "renders content wrapper with combobox data attributes" do
      output = Content.new(wrapper_id: "test-wrapper").call { "inner content" }

      assert_includes output, "inner content"
      assert_includes output, 'data-controller="combobox-content"'
      assert_includes output, 'data-wrapper-id="test-wrapper"'
    end
  end
end
