# frozen_string_literal: true

module RubyUI
  class TabsTrigger < Base
    def initialize(value:, **attrs)
      @value = value
      super(**attrs)
    end

    def view_template(&)
      button(**attrs, &)
    end

    private

    def default_attrs
      {
        type: :button,
        data: {
          ruby_ui__tabs_target: "trigger",
          action: "click->ruby-ui--tabs#show",
          value: @value
        },
        class: "inline-flex items-center justify-center whitespace-nowrap -mb-px border-b-2 border-transparent px-3 h-10 text-sm font-medium transition-colors hover:text-foreground focus-visible:outline-none disabled:pointer-events-none disabled:opacity-50 data-[state=active]:border-primary data-[state=active]:text-primary"
      }
    end
  end
end
