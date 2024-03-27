# frozen_string_literal: true

class CardComponent < ApplicationComponent
  def template(&content)
    render PhlexUI::Card.new(class!: "bg-background p-4 border border-gray-100 shadow-sm rounded-md") { content.call }
  end
end
