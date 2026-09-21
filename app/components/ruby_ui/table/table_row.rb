# frozen_string_literal: true

module RubyUI
  class TableRow < Base
    def view_template(&)
      tr(**attrs, &)
    end

    private

    def default_attrs
      {
        class: "border-b border-border transition-colors hover:bg-surface-muted data-[state=selected]:bg-primary-50"
      }
    end
  end
end
