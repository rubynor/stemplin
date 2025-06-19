# frozen_string_literal: true

class CardComponent < ApplicationComponent
  def initialize(**attrs)
    @attrs = attrs
    @class_name = @attrs.delete(:class)
  end

  def view_template(&content)
    render RubyUI::Card.new(**@attrs.merge({ class!: TAILWIND_MERGER.merge([ "bg-background p-4 border border-gray-100 shadow-sm rounded-md", @class_name ]) })) { content.call }
  end
end
