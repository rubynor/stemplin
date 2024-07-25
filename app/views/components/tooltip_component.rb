# frozen_string_literal: true

class TooltipComponent < ApplicationComponent
  def initialize(note: nil, options: {}, **trigger_attributes)
    @note = note
    @options = options.reverse_merge(placement: "right", arrow: true, animation: "fade")
    @trigger_attributes = trigger_attributes
  end

  def template(&content)
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
    render PhlexUI::Tooltip.new(options: @options) do
      render PhlexUI::Tooltip::Trigger.new(**@trigger_attributes) do
        content.call
      end
      render PhlexUI::Tooltip::Content.new(class: "bg-gray-700 bg-opacity-90 text-white shadow-none") do
        render PhlexUI::Typography::P.new { @note }
      end
    end
  end
end
