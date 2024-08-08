# frozen_string_literal: true

module ComboboxComponent
  class Group < ApplicationComponent
    def initialize(heading: nil, **attrs)
      @heading = heading
      super(**attrs)
    end

    def template(&block)
      div(**@attrs) do
        render_header if @heading
        render_items(&block)
      end
    end

    private

    def render_header
      div(group_heading: @heading, class: "px-2 py-1.5 text-xs font-medium text-gray-400") { @heading }
    end

    def render_items(&)
      div(group_items: "", role: "group", &)
    end

    def default_attrs
      {
        class:
          "overflow-hidden p-1",
        role: "presentation",
        data: {
          value: @heading,
          combobox_content_target: "group"
        }
      }
    end
  end
end
