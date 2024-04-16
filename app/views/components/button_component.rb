# frozen_string_literal: true

class ButtonComponent < ApplicationComponent
  def initialize(path: nil, method: nil, **attrs)
    @attrs = attrs
    @path = path
    @method = method
  end

  def template(&content)
    if @path.present?
      button_to(@path, method: @method) { render_button(&content) }
    else
      render_button(&content)
    end
  end

  private

  def render_button(&content)
    render PhlexUI::Button.new(**default_attrs) { content.call }
  end

  def default_attrs
    {
      **@attrs,
      type: @path.present? && @attrs[:type].nil? ? "submit" : @attrs[:type],
      class: tokens(@attrs[:class], "py-2", is_outline?: "border !border-gray-100")
    }
  end
  def is_outline?
    @attrs[:variant] == :outline
  end
end
