# frozen_string_literal: true

class ButtonComponent < ApplicationComponent
  def initialize(path: nil, method: nil, **attrs)
    @attrs = attrs
    @path = path
    @method = method
  end

  def template(&content)
    if @path.present?
      if @method == :get
        link_to(@path, **@attrs) { render_button(&content) }
      else
        button_to(@path, method: @method, **@attrs) { render_button(&content) }
      end
    else
      render_button(&content)
    end
  end

  private

  def render_button(&content)
    render PhlexUI::Button.new(**default_attrs) { content.call }
  end

  def default_type
    return "submit" if @path.present? && @attrs[:type].nil?
    return "button" if @attrs[:type].nil?
    @attrs[:type]
  end

  def default_attrs
    {
      **@attrs,
      type!: default_type,
      class: tokens(@attrs[:class], "py-2 !h-12", is_outline?: "border !border-gray-100", is_disabled?: "!pointer-events-auto !cursor-not-allowed")
    }
  end

  def is_outline?
    @attrs[:variant] == :outline
  end

  def is_disabled?
    @attrs[:disabled]
  end
end
