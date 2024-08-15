# frozen_string_literal: true

module ComboboxComponent
  # @param selected [Hash] The selected items hash
  # @option selected [String] :title The selected items title
  # @option selected [Array] :items The selected items
  # @option selected [String] :method The selected items method
  class SelectedItems < ApplicationComponent
    def initialize(**options)
      @form = options[:form]
      @method = options[:method]
      @selected = options[:selected] || {}
      @value_method = options[:value_method]
      @text_method = options[:text_method]
    end

    def template
      div(**default_attrs) do
        render_title
        render_items
        render_item_template
      end
    end

    private

    def default_attrs
      {
        data: {
          controller: "combobox-selected-items"
        },
        class: "flex flex-col gap-y-4 mb-4 border-b border-gray-200"
      }
    end

    def render_title
      div(class: "border-b border-gray-100") do
        span(class: "font-medium text-sm") { @selected[:title] }
      end
    end

    def render_items
      div(class: "flex flex-col gap-y-2 divide-y divide-gray-100") do
        @selected[:items]&.each { |item| render_item(item) }
      end
    end

    def render_item(item = nil)
      div(class: "flex flex-row items-center gap-x-4 py-2") do
        render_remove_button
        render_item_text(item)
        render_hidden_field(item)
      end
    end

    def render_remove_button
      button(type: "button", class: "border border-gray-200 py-1 px-2 rounded-md shadow-sm") do
        i(class: "uc-icon text-xl text-gray-400") { "&#xeb8e;".html_safe }
      end
    end

    def render_item_text(item = nil)
      span(class: "font-regular text-base") { item&.public_send(@text_method) }
    end

    def render_hidden_field(item = nil)
      hidden_field_tag "#{@selected[:method]}", item&.public_send(@value_method), multiple: true
    end

    def render_item_template
      content_tag(:template, data: { combobox_selected_items_target: :newItem }) do
        render_item
      end
    end
  end
end
