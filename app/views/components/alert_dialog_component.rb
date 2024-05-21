# frozen_string_literal: true

class AlertDialogComponent < ApplicationComponent
  def template
    content_tag(:dialog, id: "turbo-confirm-dialog", class: "backdrop:bg-gray-900 backdrop:bg-opacity-80 h-modal rounded-lg shadow-xl") do
      content_tag(:form, method: :dialog) do
        content_tag(:div, class: "relative transform overflow-hidden rounded-lg bg-white text-left shadow-xl transition-all min-w-96") do
          content_tag(:div, class: "bg-white px-4 pb-4 pt-5 sm:p-6 sm:pb-4 mb-5") do
            content_tag(:div, class: "sm:flex sm:items-start") do
              content_tag(:div, class: "mx-auto flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10") do
                content_tag(:i, "&#xe99b;".html_safe, class: "uc-icon text-red-600 text-lg")
              end
              content_tag(:div, class: "mt-3 text-center sm:ml-4 sm:mt-0 sm:text-left") do
                content_tag(:h2, class: "text-base font-semibold leading-6 text-gray-900") do
                  I18n.t("alert.wish_to_proceed")
                end
                content_tag(:div, class: "mt-2") do
                  content_tag(:p, class: "text-sm text-gray-500 w-96") do
                    ""
                  end
                end
              end
            end
          end
          content_tag(:div, class: "bg-gray-50 px-4 py-3 flex flex-row-reverse sm:px-6") do
            content_tag(:div, class: "flex flex-row gap-x-2") do
              render ButtonComponent.new(type: "submit", value: "cancel", variant: :outline) { I18n.t("common.stop") }
              render ButtonComponent.new(type: "submit", value: "confirm") { I18n.t("common.accept") }
            end
          end
        end
      end
    end
  end
end
