# frozen_string_literal: true

module RubyUI
  class Input < Base
    def initialize(type: :string, **attrs)
      @type = type.to_sym
      super(**attrs)
    end

    def view_template
      input(type: @type, **attrs)
    end

    private

    def default_attrs
      {
        data: {
          ruby_ui__form_field_target: "input",
          action: "input->ruby-ui--form-field#onInput invalid->ruby-ui--form-field#onInvalid"
        },
        class: "flex h-10 w-full rounded-lg border border-input bg-background px-3 text-sm shadow-xs transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/40 focus-visible:ring-offset-1 focus-visible:border-primary disabled:cursor-not-allowed disabled:opacity-50 placeholder:text-muted-foreground"
      }
    end
  end
end
