# frozen_string_literal: true

module ComboboxComponent
  class Empty < ApplicationComponent
    def view_template(&)
      div(**@attrs, &)
    end

    private

    def default_attrs
      {
        class: "hidden py-6 text-center text-sm",
        role: "presentation",
        data: { combobox_content_target: "empty" }
      }
    end
  end
end
