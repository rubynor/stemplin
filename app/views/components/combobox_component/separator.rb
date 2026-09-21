# frozen_string_literal: true

module ComboboxComponent
  class Separator < ApplicationComponent
    def view_template(&)
      div(**@attrs, &)
    end

    private

    def default_attrs
      { class: "-mx-1 h-px bg-secondary" }
    end
  end
end
