# frozen_string_literal: true

class WizardStepsComponent < ApplicationComponent
  def initialize(current_step: 0)
    @current_step = current_step
    @steps = [
      {
        key: :client
      },
      {
        key: :project
      },
      {
        key: :task
      }
    ]
  end

  def view_template
    content_tag(:div, class: "flex flex-row gap-x-12") do
      @steps.each_with_index do |step, index|
        content_tag(:div, class: "flex flex-col items-center justify-center gap-y-2") do
          content_tag(:span, index + 1, class: wizard_step_class(index))
          content_tag(:span, step[:key], class: "text-sm font-semibold text-gray-500")
        end
      end
    end
  end

  private

  def wizard_step_class(index)
    if index == @current_step
      "bg-primary-700 text-white rounded-full w-10 h-10 flex items-center justify-center font-semibold"
    elsif index < @current_step
      "bg-gray-200 text-gray-500 rounded-full w-10 h-10 flex items-center justify-center font-semibold"
    else
      "bg-gray-200 text-gray-500 rounded-full w-10 h-10 flex items-center justify-center font-semibold"
    end
  end

  def default_attrs
    {
      variant: @variant,
      class: TAILWIND_MERGER.merge([ "py-4 px-6 flex flex-row items-start gap-x-2 !ring-2 shadow-sm", @options[:class_names] ])
    }
  end
end
