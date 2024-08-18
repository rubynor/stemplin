# frozen_string_literal: true

module ComboboxComponent
  class Trigger < ApplicationComponent
    def initialize(placeholder:, size: nil, **attrs)
      @placeholder = placeholder
      @size = size
      super(**attrs)
    end

    def template
      button(**@attrs, type: "button") do
        span(data: { combobox_target: "content" }) { @placeholder }
        icon
      end
    end

    private

    def icon
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        viewbox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        class: "ml-2 h-4 w-4 shrink-0 opacity-50",
        stroke_width: "2",
        stroke_linecap: "round",
        stroke_linejoin: "round"
      ) do |s|
        s.path(
          d: "m7 15 5 5 5-5"
        )
        s.path(
          d: "m7 9 5-5 5 5"
        )
      end
    end

    def default_attrs
      {
        class: tokens(
          "inline-flex items-center whitespace-nowrap rounded-md text-sm transition-colors disabled:pointer-events-none disabled:opacity-50 border border-gray-200 bg-background hover:bg-gray-100 text-gray-600 font-regular h-10 px-4 py-2 w-[200px] justify-between z-10",
          @size
        ),
        data: {
          action: "combobox#onClick",
          combobox_target: "input"
        },
        role: "combobox", variant: "outline",
        aria: {
          expanded: "false",
          haspopup: "listbox",
          autocomplete: "none"
        }
      }
    end
  end
end
