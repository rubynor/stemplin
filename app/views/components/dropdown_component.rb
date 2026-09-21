class DropdownComponent < ApplicationComponent
  def initialize(options: {}, **attrs)
    @close_background_delay = options.fetch(:close_background_delay, false)
    super(**attrs)
  end

  def view_template(&block)
    div(**@attrs, &block)
  end

  private

  def default_attrs
    {
      data: {
        controller: "custom-dropdown",
        action: "keyup@window->custom-dropdown#closeWithKeyboard click@window->custom-dropdown#closeBackground",
        custom_dropdown_close_background_delay_value: @close_background_delay
      }
    }
  end

  def default_classes
    "relative custom-dropdown-component cursor-pointer"
  end
end
