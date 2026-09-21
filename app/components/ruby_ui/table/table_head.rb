# frozen_string_literal: true

module RubyUI
  class TableHead < Base
    def view_template(&)
      th(**attrs, &)
    end

    private

    def default_attrs
      {
        class: "h-11 px-3 text-left align-middle text-xs font-semibold uppercase tracking-wide text-muted-foreground [&:has([role=checkbox])]:pr-0 [&>[role=checkbox]]:translate-y-[2px]"
      }
    end
  end
end
