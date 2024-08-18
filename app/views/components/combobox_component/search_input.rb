# frozen_string_literal: true

module ComboboxComponent
  class SearchInput < ApplicationComponent
    def initialize(placeholder:, **attrs)
      @placeholder = placeholder
      @can_add = attrs[:can_add]
      @wrapper_id = attrs[:wrapper_id]
      super(**attrs)
    end

    def template
      div(class: "flex flex-col") do
        input_container do
          search_icon
          input(**@attrs)
        end
        if @can_add
          div(class: "p-2 hidden", data: { combobox_content_target: "empty" }) do
            button(**search_btn_attrs) do
              span(class: "font-medium text-white text-xs") { "Add to list" }
              i(class: "uc-icon text-lg text-white") { "&#xe9c7;".html_safe }
            end
          end
        end
      end
    end

    private

    def search_icon
      svg(
        xmlns: "http://www.w3.org/2000/svg",
        viewbox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        class: "mr-2 h-4 w-4 shrink-0 opacity-50",
        stroke_width: "2",
        stroke_linecap: "round",
        stroke_linejoin: "round"
      ) do |s|
        s.circle(cx: "11", cy: "11", r: "8")
        s.path(
          d: "m21 21-4.3-4.3"
        )
      end
    end

    def input_container(&)
      div(class: "flex items-center border-b px-3", &)
    end

    def default_attrs
      {
        class:
          "flex h-10 w-full rounded-md bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50 border-none focus:ring-transparent",
        placeholder: @placeholder,
        data: {
          action: "input->combobox-content#filter",
          combobox_target: "search",
          combobox_content_target: "search",
          wrapper_id: @wrapper_id
        },
        autocomplete: "off",
        autocorrect: "off",
        spellcheck: false
      }
    end

    def search_btn_attrs
      {
        type: "button",
        data: {
          action: "click->combobox-content#addItem"
        },
        class: "bg-primary-600 rounded-md py-1 w-full flex justify-center items-center gap-x-2"
      }
    end
  end
end
