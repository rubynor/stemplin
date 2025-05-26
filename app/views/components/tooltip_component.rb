# frozen_string_literal: true

class TooltipComponent < ApplicationComponent
  def initialize(note: nil, options: {}, **trigger_attributes)
    @note = note
    @options = options.reverse_merge(placement: "right", arrow: true, animation: "fade")
    @trigger_attributes = trigger_attributes
  end

  def view_template(&content)
    if @note.blank?
      content.call
    else
      render_tooltip(content)
    end
  end

  private

  def render_tooltip(content)
    # Ref: https://github.com/PhlexUI/phlex_ui_stimulus/blob/main/controllers/popover_controller.js#L2
    # It is built on top of tippy.js https://github.com/atomiks/tippyjs
    render RubyUI::Tooltip.new(options: @options) do
      render RubyUI::TooltipTrigger.new(**@trigger_attributes) do
        content.call
      end
      render RubyUI::TooltipContent.new(class: "bg-gray-700 bg-opacity-90 text-white shadow-none") do
        render RubyUI::Text.new { @note }
      end
    end
  end
end
