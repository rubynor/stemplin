# frozen_string_literal: true

class SplitButtonComponent < ApplicationComponent
  BUTTON_CLASSES = "h-10 px-4 gap-x-2 inline-flex items-center justify-center whitespace-nowrap text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/40 disabled:pointer-events-none disabled:opacity-50"
  OUTLINE_CLASSES = "bg-background border border-input text-secondary-text shadow-xs hover:bg-accent"

  def initialize(path: nil, method: nil, dropdown_items: [], **attrs)
    @path = path
    @method = method
    @dropdown_items = dropdown_items
    @attrs = attrs
  end

  def view_template(&content)
    render RubyUI::DropdownMenu.new(options: { placement: "bottom-end" }) do
      div(class: "inline-flex") do
        render_main_button(&content)
        render_dropdown_trigger
      end
      render_dropdown_content
    end
  end

  private

  def render_main_button(&content)
    button_classes = "#{BUTTON_CLASSES} #{OUTLINE_CLASSES} rounded-l-lg border-r-0 #{@attrs[:class]}"

    if @path.present?
      if @method == :get
        a(href: @path, class: button_classes, &content)
      else
        form(action: @path, method: "post", class: "inline", data: { turbo: true }) do
          input(type: "hidden", name: "_method", value: @method.to_s) if @method != :post
          input(type: "hidden", name: "authenticity_token", value: helpers.form_authenticity_token)
          button(type: "submit", class: button_classes, &content)
        end
      end
    else
      button(type: "button", class: button_classes, &content)
    end
  end

  def render_dropdown_trigger
    render RubyUI::DropdownMenuTrigger.new do
      button(
        type: "button",
        class: "#{BUTTON_CLASSES} #{OUTLINE_CLASSES} rounded-r-lg px-2"
      ) do
        i(class: "uc-icon text-base") { raw safe("&#xe819;") }
      end
    end
  end

  def render_dropdown_content
    render RubyUI::DropdownMenuContent.new do
      @dropdown_items.each do |item|
        render RubyUI::DropdownMenuItem.new(href: item[:path], class: "hover:bg-accent", data: { turbo_method: item[:method] || :get }) do
          span { raw item[:label].html_safe }
        end
      end
    end
  end
end
