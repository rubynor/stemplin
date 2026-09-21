# frozen_string_literal: true

module RubyUI
  class TabsList < Base
    def view_template(&)
      div(**attrs, &)
    end

    private

    def default_attrs
      {
        class: "inline-flex h-10 items-center justify-start gap-x-1 border-b border-border w-full text-muted-foreground"
      }
    end
  end
end
