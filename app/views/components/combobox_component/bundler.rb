# frozen_string_literal: true

module ComboboxComponent
  # @param form [ActionView::Helpers::FormBuilder] The form builder object
  # @param method [Symbol] The method/attribute name for the form field
  # @param collection [Enumerable] The collection of items to select from
  # @param value_method [Symbol] The method to call on collection items to get the option value
  # @param text_method [Symbol] The method to call on collection items to get the option text
  # @param placeholder [String] The placeholder text for the combobox trigger
  # @param search_placeholder [String] The placeholder text for the search input
  # @param selected [Hash] The selected items hash
  # @option selected [String] :title The selected items title
  # @option selected [Array] :items The selected items
  class Bundler < ApplicationComponent
    MODES = { single: :single, multiple: :multiple }.freeze

    def initialize(**options)
      @unique_id = "combobox##{SecureRandom.hex(4)}"
      @options = options.with_indifferent_access
      @mode = MODES[@options[:mode]&.to_sym] || MODES[:single]
    end

    def template
      render ComboboxComponent::Main.new(id: @unique_id) do
        render_selected_or_collection
        render ComboboxComponent::Trigger.new(placeholder: @options[:placeholder], aria_controls: "list", size: :fill)
        render_content
      end
    end

    private

    def render_selected_or_collection
      component = multiple? ? SelectedItems : CollectionSelect
      render component.new(**common_props) if should_render_selection?
    end

    def render_content
      render ComboboxComponent::Content.new(wrapper_id: @unique_id) do
        render ComboboxComponent::SearchInput.new(placeholder: @options[:search_placeholder])
        render_list
      end
    end

    def render_list
      render ComboboxComponent::List.new(wrapper_id: @unique_id) do
        render ComboboxComponent::Empty.new { "No results found." }
        @options[:collection]&.each { |item| render_item(item) }
        render_item_template
      end
    end

    def render_item(item = nil)
      render ComboboxComponent::Item.new(wrapper_id: @unique_id, value: item&.public_send(@options[:value_method])) do |component|
        component.span { item&.public_send(@options[:text_method]) }
      end
    end

    def render_item_template
      content_tag(:template, data: { combobox_content_target: :optionTemplate }) do
        render_item
      end
    end

    def multiple?
      @mode == MODES[:multiple]
    end

    def should_render_selection?
      multiple? ? @options[:selected].present? : true
    end

    def common_props
      props = @options.slice(:form, :method, :collection, :value_method, :text_method, :selected)
      props[:wrapper_id] = @unique_id
      props
    end
  end
end
