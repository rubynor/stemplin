# frozen_string_literal: true

module ComboboxComponent
  class Main < ApplicationComponent
    def view_template(&)
      div(**@attrs, &)
    end

    private

    def default_attrs
      {
        data: {
          controller: "combobox",
          action: "click@window->combobox#clickOutside",
          combobox_closed_value: "true"
        },
        class: "relative flex flex-col"
      }
    end
  end
end
