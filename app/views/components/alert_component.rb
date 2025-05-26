# frozen_string_literal: true

class AlertComponent < ApplicationComponent
  def initialize(title:, message:, variant: nil)
    @title = title
    @message = message
    @variant = variant
    @options = set_options
  end

  def view_template
    render RubyUI::Alert.new(**default_attrs) do
      image_tag(@options[:icon], class: "h-8")
      content_tag(:div, class: "flex flex-col") do
        content_tag(:h3, @title, class: "text-base font-semibold")
        content_tag(:p, formatted_message, class: "text-sm")
      end
    end
  end

  private

  def set_options
    case @variant
    when :info
      { icon: "info_circle.svg", class_names: "bg-gray-50 text-gray-600 !ring-gray-300" }
    when :warning
      { icon: "warning_circle.svg", class_names: "bg-warning text-warning-foreground !ring-yellow-300" }
    when :success
      { icon: "success_circle.svg", class_names: "bg-success text-success-foreground !ring-green-300" }
    when :destructive
      { icon: "error_circle.svg", class_names: "bg-destructive text-destructive-foreground !ring-red-300" }
    else
      { icon: "info_circle.svg", class_names: "bg-gray-50 text-gray-600 !ring-gray-300" }
    end
  end

  def default_attrs
    {
      variant: @variant,
      class: TAILWIND_MERGER.merge(["py-4 px-6 flex flex-row items-start gap-x-2 !ring-2 shadow-sm", @options[:class_names]])
    }
  end

  def formatted_message
    case @message
    when Array
      helpers.simple_format(@message.join("\n"))
    else
      @message
    end
  end
end
