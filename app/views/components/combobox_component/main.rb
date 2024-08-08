# frozen_string_literal: true

module ComboboxComponent
  class Main < ApplicationComponent
    def template(&)
      div(**@attrs, &)
    end

    private

    def default_attrs
      {
        data: {
          controller: "combobox",
          action: "click@window->combobox#clickOutside",
          combobox_closed_value: "true"
        }
      }
    end
  end
end
