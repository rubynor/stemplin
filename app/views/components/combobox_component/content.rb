# frozen_string_literal: true

module ComboboxComponent
  class Content < ApplicationComponent
    def template(&)
      div(**@attrs) do
        div(
          data: {
            controller: "combobox-content",
            action: "keydown.up->combobox-content#handleKeyUp keydown.down->combobox-content#handleKeyDown keydown.enter->combobox-content#handleKeyEnter keydown.esc->combobox-content#handleKeyEsc"
          },
          class: "flex h-full w-full flex-col overflow-hidden rounded-md rounded-lg border shadow-md bg-white", &
        )
      end
    end

    private

    def default_attrs
      {
        data: { combobox_target: "popover" },
        class: "invisible absolute top-0 left-0 p-1.5 rounded"
      }
    end
  end
end
