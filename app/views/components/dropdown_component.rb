class DropdownComponent < ApplicationComponent
  def initialize(options: {}, **attrs)
    @close_background_delay = options.fetch(:close_background_delay, false)
    super(**attrs)
  end

  def template(&block)
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

class DropdownComponent::Trigger < ApplicationComponent
  def initialize(**attrs)
    super(**attrs)
  end

  def template(&block)
    div(**@attrs, &block)
  end

  private

  def default_attrs
    {
      data: {
        custom_dropdown_target: "trigger",
        action: "click->custom-dropdown#toggleContent"
      }
    }
  end
end

class DropdownComponent::Content < ApplicationComponent
  def initialize(**attrs)
    super(**attrs)
  end

  def template(&block)
    div(**@attrs, &block)
  end

  private

  def default_attrs
    {
      data: {
        custom_dropdown_target: "content"
      }
    }
  end

  def default_classes
    "z-50 rounded-md border bg-background p-2 text-foreground shadow-md outline-none mt-2 hidden left-0 custom-dropdown-component-content cursor-default"
  end
end
