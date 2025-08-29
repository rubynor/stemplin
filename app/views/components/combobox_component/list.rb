# frozen_string_literal: true

module ComboboxComponent
  class List < ApplicationComponent
    def initialize(**attrs)
      @wrapper_id = attrs[:wrapper_id]
      super
    end

    def view_template(&)
      div(**@attrs, &)
    end

    private

    def default_attrs
      {
        data: {
          combobox_content_target: "list",
          wrapper_id: @wrapper_id
        },
        role: "listbox",
        tabindex: "-1",
        class: "max-h-[300px] overflow-y-auto overflow-x-hidden"
      }
    end
  end
end
