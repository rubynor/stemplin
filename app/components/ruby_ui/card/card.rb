# frozen_string_literal: true

module RubyUI
  class Card < Base
    def view_template(&)
      div(**attrs, &)
    end

    private

    def default_attrs
      {
        class: "rounded-xl border border-border bg-background shadow-card"
      }
    end
  end
end
