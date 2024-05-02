# frozen_string_literal: true

# @param type [String] Classic notification type `error`, `alert` and `info` + custom `success`
# @param data [String, Hash] `String` for backward compatibility,
#   `Hash` for the new functionality `{title: "", body: "", timeout: 5, countdown: false, action: { url: "", method: "", name: ""}, variant: [:primary :secondary]}`.
#   The `title` attribute for `Hash` is mandatory.
class SnackbarComponent < ApplicationComponent
  def initialize(type:, data:)
    @type = type
    @data = prepare_data(data)
    @icon_class = icon_class
    @icon = icon

    @data[:timeout] ||= 6
    @data[:action][:method] ||= "get" if @data[:action]
    @data[:variant] ||= :primary
    @data[:countdown] ||= false
  end

  def template
    content_tag(:div, class: "snackbar") do
      content_tag(:div, **wrapper_options) do
        content_tag(:div, class: "rounded-lg shadow-sm overflow-hidden") do
          content_tag(:div, class: "p-4") do
            content_tag(:div, class: "flex items-start") do
              content_tag(:div, class: "h-6 w-6") do
                content_tag(:i, @icon.html_safe, class: @icon_class) if @icon.present?
              end
              content_tag(:div, **text_wrapper_options) do
                content_tag(:div, class: "w-full") do
                  content_tag(:p, @data[:title], class: "text-sm leading-5 font-medium")
                  if @data[:body].present?
                    content_tag(:p, @data[:body], class: "mt-1 text-sm leading-5")
                  end
                end
                content_tag(:div, class: "flex items-center gap-x-6 justify-end") do
                  if @data[:action].present?
                    action_btn
                  end
                end
              end
              content_tag(:button, class: "inline-flex focus:outline-none transition ease-in-out duration-150", data: { action: "snackbar#close" }) do
                content_tag(:i, "&#xeb8e;".html_safe, class: "uc-icon text-gray-600 text-xl")
              end
            end
          end
          if @data[:countdown]
            content_tag(:div, class: "bg-primary rounded-lg h-1 w-0",  data: { "snackbar-target": "countdown" }) do
              ""
            end
          end
        end
      end
    end
  end

  attr_reader :data, :type

  def wrapper_options
    {
      class: tokens(
        "snackbar__container sm:w-96 transition duration-300 ease-in-out shadow-xl opacity-0 translate-x-16",
        snackbar_variant
      ),
      data: {
        controller: "snackbar",
        snackbar_timeout_value: data[:timeout],
        "snackbar-action-url": data.dig(:action, :url),
        "snackbar-action-method": data.dig(:action, :method)
      }
    }
  end

  def text_wrapper_options
    {
      class: tokens(
        "ml-3 flex w-full",
        text_ordering
      )
    }
  end

  def action_btn
    action = data.dig(:action)

    if action.present?
      method = action.dig(:method)
      url = action.dig(:url)
      name = action.dig(:name)
      data_attributes = action.dig(:data_attributes)

      button_to url, method: method, class: "text-sm leading-5 font-medium snackbar__action focus:outline-none focus:underline transition ease-in-out duration-150 decoration-none", data: { "snackbar-target": "actionButton" }.merge(data_attributes) do
        name
      end
    end
  end

  private

  def text_ordering
    is_title_and_body_available = data[:title].present? && data[:body].present?
    is_text_content_long = (data[:title].present? && data[:title].length > 34) || (data[:body].present? && data[:body].length > 34)

    if is_title_and_body_available || is_text_content_long # displayed in column anytime `title` and `body` are provided but also when text is long
      "flex-col gap-y-4"
    elsif !is_title_and_body_available && !is_text_content_long # only displayed in a row when both are not available and action one of them not long
      "justify-between items-center"
    else
      ""
    end
  end

  def snackbar_variant
    case data[:variant].to_sym
    when :primary
      "snackbar-primary"
    when :secondary
      "snackbar-secondary"
    else
      "snackbar-primary"
    end
  end

  def icon_class
    case type
    when "success"
      "uc-icon text-xl text-green-600"
    when "error"
      "uc-icon text-xl text-red-600"
    when "alert"
      "uc-icon text-xl text-orange-600"
    else
      "uc-icon text-xl text-blue-600"
    end
  end

  def icon
    case type
    when "success"
      "&#xe8b0;"
    when "error"
      "&#xe99b;"
    when "alert"
      "&#xe99b;"
    else
      "&#xea39;"
    end
  end

  def prepare_data(data)
    case data
    when Hash
      data.deep_symbolize_keys
    else
      { title: data }
    end
  end
end
