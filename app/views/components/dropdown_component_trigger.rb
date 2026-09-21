class DropdownComponentTrigger < ApplicationComponent
  def initialize(**attrs)
    super(**attrs)
  end

  def view_template(&block)
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

  def default_classes
    "z-0"
  end
end
