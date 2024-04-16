# frozen_string_literal: true

class CardComponent < ApplicationComponent
  def initialize(**attrs)
    @attrs = attrs
    @class_name = @attrs.delete(:class)
  end

  def template(&content)
    render PhlexUI::Card.new(**@attrs.merge({ class!: tokens("bg-background p-4 border border-gray-100 shadow-sm rounded-md", @class_name) })) { content.call }
  end
end
