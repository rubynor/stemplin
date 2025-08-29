# frozen_string_literal: true

# Note: This is mostly a replica of new phlex-ui unreleased component plus our custom features
#  - list view
#  - add & remove items to list
#  - create new item

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
  # @param can_add [Boolean] This value will determin if it can add new items
  class Bundler < ApplicationComponent
    MODES = { single: :single, multiple: :multiple }.freeze

    SIZES = { fixed: "w-[200px]", fill: "w-full" }.freeze

    def initialize(**options)
      @unique_id = "combobox##{SecureRandom.hex(4)}"
      @options = options.with_indifferent_access
      @mode = MODES[@options[:mode]&.to_sym] || MODES[:single]
      @can_add = options.fetch(:can_add, false)
      @size = SIZES[@options[:size]&.to_sym] || SIZES[:fixed]
    end

    def view_template
      render ComboboxComponent::Main.new(id: @unique_id) do
        render_selected_or_collection
        render ComboboxComponentTrigger.new(placeholder: @options[:placeholder], aria_controls: "list", size: @size)
        render_content
      end
    end

    private

    def render_selected_or_collection
      component = multiple? ? SelectedItems : CollectionSelect
      render component.new(**common_props) if should_render_selection?
    end

    def render_content
      render ComboboxComponent::Content.new(wrapper_id: @unique_id, size: @size) do
        render ComboboxComponent::SearchInput.new(placeholder: @options[:search_placeholder], can_add: @can_add, wrapper_id: @unique_id)
        render ComboboxComponent::Empty.new { t("components.combobox.empty.note") } unless @can_add
        render_list
      end
    end

    def render_list
      render ComboboxComponent::List.new(wrapper_id: @unique_id) do
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
