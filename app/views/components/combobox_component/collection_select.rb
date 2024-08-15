# frozen_string_literal: true

module ComboboxComponent
  class CollectionSelect < ApplicationComponent
    def initialize(**options)
      @form = options[:form]
      @method = options[:method]
      @collection = options[:collection]
      @value_method = options[:value_method]
      @text_method = options[:text_method]
      @html_options = options[:html_options] || {}
      @select_options = options[:select_options] || {}
    end

    def template
      plain(render_collection_select)
    end

    private

    def render_collection_select
      @form.collection_select(
        @method,
        @collection,
        @value_method,
        @text_method,
        @select_options,
        default_html_options.merge(@html_options)
      )
    end

    def default_html_options
      {
        class: "pointer-events-none absolute -z-10 opacity-0",
        data: { combobox_target: "select" },
        required: true
      }
    end
  end
end
