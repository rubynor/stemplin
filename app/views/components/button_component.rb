# frozen_string_literal: true

class ButtonComponent < ApplicationComponent
  def initialize(path: nil, method: nil, **attrs)
    @attrs = attrs
    @path = path
    @method = method
    @attrs[:type] = "submit" if @path.present? && @attrs[:type].nil?
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
    render PhlexUI::Button.new(**@attrs) { content.call }
  end
end
