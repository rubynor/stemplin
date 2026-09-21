# frozen_string_literal: true

class ButtonComponent < ApplicationComponent
  module Styles
    BASE = "!h-10 px-4 gap-x-2 text-sm font-medium !rounded-lg transition-colors " \
           "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/40 focus-visible:ring-offset-1"
    ICON_BASE = "!h-9 !w-9 !p-0 !rounded-lg"

    VARIANTS = {
      primary: "!bg-primary-600 !text-white hover:!bg-primary-700 !shadow-xs",
      secondary: "!bg-primary-50 !text-primary-700 hover:!bg-primary-100 !shadow-none",
      outline: "!bg-background !border !border-input !text-secondary-text hover:!bg-accent !shadow-xs",
      ghost: "!bg-transparent hover:!bg-accent !text-secondary-text !shadow-none",
      destructive: "!bg-transparent !text-destructive-foreground hover:!bg-destructive !shadow-none",
      none: "font-medium text-sm shadow-xs px-4 rounded-lg"
    }

    STATES = {
      disabled: "opacity-50 !cursor-not-allowed",
      loading: "opacity-75 !cursor-wait"
    }

    def self.compose(variant, state = nil, custom_class = nil, icon = false)
      [
        icon ? ICON_BASE : BASE,
        VARIANTS[variant] || VARIANTS[:primary],
        state ? STATES[state] : nil,
        custom_class
      ].compact.join(" ")
    end
  end

  def initialize(path: nil, method: nil, form: {}, **attrs)
    @attrs = attrs
    @path = path
    @method = method
    @form_options = form
  end

  def view_template(&content)
    if @path.present?
      if @method == :get || @method.nil?
        link_to(@path, **@attrs) { render_button(&content) }
      else
        render_form_with_button(&content)
      end
    else
      render_button(&content)
    end
  end

  def render_form_with_button(&content)
    form_tag(@path, method: @method, **form_attrs) do
      render_button(&content)
    end
  end

  private

  def render_button(&content)
    render RubyUI::Button.new(**default_attrs) { content.call }
  end

  def form_attrs
    { class: "inline" }.merge(@form_options)
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

    Styles.compose(variant, state, @attrs[:class], @attrs[:icon])
  end
end
