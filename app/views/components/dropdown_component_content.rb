class DropdownComponentContent < ApplicationComponent
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
        custom_dropdown_target: "content"
      }
    }
  end

  def default_classes
    "z-50 rounded-xl border border-border bg-background p-2 text-foreground shadow-pop outline-none mt-2 hidden left-0 custom-dropdown-component-content cursor-default max-h-[20rem] overflow-auto"
  end
end
