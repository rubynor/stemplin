# frozen_string_literal: true

class ButtonComponent < ApplicationComponent
  module Styles
    BASE = "py-2 !h-12"

    VARIANTS = {
      primary: "!bg-primary-600 !text-white hover:!bg-primary-700",
      secondary: "!bg-primary-100 !text-primary-600 hover:!bg-primary-200",
      outline: "!bg-transparent border !border-gray-300 !text-gray-600 hover:!bg-gray-100",
      ghost: "!bg-transparent hover:!bg-gray-100 !text-gray-600",
      destructive: "!bg-red-100 !text-red-600 hover:!bg-red-200",
      none: "font-medium text-sm shadow px-4 rounded-md"
    }

    STATES = {
      disabled: "opacity-50 !cursor-not-allowed",
      loading: "opacity-75 !cursor-wait"
    }

    def self.compose(variant, state = nil, custom_class = nil)
      [
        BASE,
        VARIANTS[variant] || VARIANTS[:primary],
        state ? STATES[state] : nil,
        custom_class
      ].compact.join(" ")
    end
  end

  def initialize(path: nil, method: nil, **attrs)
    @attrs = attrs
    @path = path
    @method = method
  end

  def view_template(&content)
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
    render RubyUI::Button.new(**default_attrs) { content.call }
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
      class: button_classes
    }
  end

  def button_classes
    variant = @attrs[:variant] || :primary
    state = :disabled if @attrs[:disabled]
    state = :loading if @attrs[:loading]

    Styles.compose(variant, state, @attrs[:class])
  end
end
