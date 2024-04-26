# frozen_string_literal: true

class FileUploadComponent < ApplicationComponent
  include Phlex::Rails::Helpers::FileFieldTag

  def initialize(form:, attribute:, caption: nil, **attrs)
    @form = form
    @attribute = attribute
    @id = "file_upload_#{rand(10**6)}"
    @attrs = attrs
    @options = set_options
    @caption = caption
  end

  def template
    content_tag(:div, data: { controller: stimulus_controller_name }) do
      content_tag(:div, data: { file_upload_target: :fileUploadSection }, class: "drag-and-drop-wrapper w-full p-16 bg-gray-50 flex flex-col justify-center items-center cursor-pointer relative group rounded-md") do
        content_tag(:div, id: "dark-overlay", class: "drag-and-drop-overlay transition duration-500 pointer-events-none") do
          ""
        end
        file_field_tag(@attribute, **@options, **@attrs)
        image_tag("upload_doc.svg", class: "h-16")
        content_tag(:span, I18n.t("common.drag_and_drop_message"), class: "font-regular text-base my-4 text-gray-600")
        render ButtonComponent.new(variant: :secondary) { I18n.t("common.browse_a_file_from_your_computer") }
      end
      if @caption
        content_tag(:div, class: "my-4 text-sm text-gray-400") do
          @caption
        end
      end
      content_tag(:div, class: "mt-8 flex flex-wrap gap-8 w-full", data: { file_upload_target: :uploadedContent }) do
        content_tag(:template, data: { file_upload_target: :fileTemplate }) do
          content_tag(:div, class: "flex flex-col w-20 transition duration-300 opacity-0 transform translate-y-8") do
            content_tag(:button, class: "peer self-end mr-2", type: :button, data: { action: "#{stimulus_controller_name}#removeFile" }) do
              image_tag("close_btn.svg", class: "h-4")
            end
            content_tag(:div, class: "peer-hover:opacity-30 transition duration-200 w-full flex justify-center") do
              image_tag("doc.svg", class: "h-12 hidden documentIcon")
              image_tag("image_doc.svg", class: "h-12 hidden imageIcon")
            end
            content_tag(:div, class: "peer-hover:opacity-30 transition duration-200 truncate") do
              content_tag(:span, class: "text-sm filename") do
                ""
              end
            end
          end
        end
      end
    end
  end

  private

  def set_options
    {
      class: "absolute w-full h-full opacity-0 overflow-hidden cursor-pointer",
      data: {
        action: "#{stimulus_controller_name}#selectUpload drop->#{stimulus_controller_name}#dropUpload dragleave->#{stimulus_controller_name}#dragLeaveHandler dragenter->#{stimulus_controller_name}#dragEnterHandler",
        file_upload_target: :fileInput
      }
    }
  end

  def stimulus_controller_name
    "file-upload"
  end
end
