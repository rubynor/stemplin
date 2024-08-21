# frozen_string_literal: true

module ComboboxComponent
  class Item < ApplicationComponent
    def initialize(value: nil, **attrs)
      @value = value
      @wrapper_id = attrs[:wrapper_id]
      super(**attrs)
    end

    def template(&block)
      div(**@attrs) do
        div(class: "invisible text-primary-600", data: { combobox_item_target: "check" }) { icon }
        block.call
      end
    end

    private

    def icon
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        viewbox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        class: "mr-2 h-4 w-4",
        stroke_width: "2",
        stroke_linecap: "round",
        stroke_linejoin: "round"
      ) do |s|
        s.path(
          d: "M20 6 9 17l-5-5"
        )
      end
    end

    def default_attrs
      {
        class:
          "relative flex cursor-pointer select-none items-center gap-x-2 rounded-sm px-2 py-1.5 text-sm outline-none hover:bg-gray-100 aria-selected:bg-gray-100 aria-selected:text-primary-600 text-gray-600 data-[disabled]:pointer-events-none data-[disabled]:opacity-50 cursor-pointer",
        data: {
          value: @value,
          selected: false,
          combobox_content_target: "item",
          controller: "combobox-item",
          action: "click->combobox-item#selectItem mouseenter->combobox-item#mouseenter",
          wrapper_id: @wrapper_id
        },
        tabindex: "0",
        role: "option"
      }
    end
  end
end
