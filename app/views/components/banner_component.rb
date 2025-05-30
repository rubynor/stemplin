# frozen_string_literal: true

# action: { url: "", method: "", name: ""}
class BannerComponent < ApplicationComponent
  def initialize(message: nil, title: nil, variant: nil, dismissible: true, action: {})
    @title = title
    @message = message
    @variant = variant
    @dismissible = dismissible
    @action = action
    @action[:method] ||= "get" if action[:url].present?
    @options = set_options
  end

  def view_template
    if @message.present?
      content_tag(:div, class: TAILWIND_MERGER.merge([ "flex justify-center items-center py-2.5 px-4 mx-auto relative shadow", @options[:container_class_names] ])) do
        link_to @action[:url] || "#", method: @action[:method], class: "flex-1 items-center" do
          content_tag(:div, class: "flex flex-col lg:flex-row lg:items-center gap-1 lg:justify-center") do
            content_tag(:div, class: "flex flex-row gap-x-1 items-center") do
              content_tag(:i, @options[:icon].html_safe, class: "uc-icon text-xl")
              content_tag(:span, @title || @options[:title], class: "font-semibold")
            end
            content_tag(:span, "-", class: "mx-1 hidden lg:block")
            content_tag(:span, @message, class: "font-normal text-left")
            content_tag(:span, "→", "aria-hidden": true, class: "ml-4 hidden lg:block")
          end
        end
        if @dismissible
          content_tag(:div, class: "absolute right-4 top-0 flex items-center") do
            content_tag(:button, type: "button", class: "p-2 focus-visible:outline-offset-[-4px]") do
              content_tag(:i, "&#xeb8e;".html_safe, class: "uc-icon text-white text-xl")
            end
          end
        end
      end
    end
  end

  private

  def set_options
    case @variant
    when :info
      { icon: "&#xea39;", tile: I18n.t("helpers.alert.info"), container_class_names: "bg-blue-500 text-white" }
    when :warning
      { icon: "&#xe99b;", tile: I18n.t("helpers.alert.info"), container_class_names: "bg-yellow-500 text-white" }
    when :success
      { icon: "&#xe8b0;", tile: I18n.t("helpers.alert.info"), container_class_names: "bg-green-500 text-white" }
    when :destructive
      { icon: "&#xe99b;", tile: I18n.t("helpers.alert.info"), container_class_names: "bg-red-500 text-white" }
    else
      { icon: "&#xea39;", tile: I18n.t("helpers.alert.info"), container_class_names: "bg-blue-500 text-white" }
    end
  end
end
