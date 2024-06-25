class SelectMultipleComponent < ApplicationComponent
  def initialize(form, method, collection, value_method, text_method, options, label: nil, **attrs)
    @form = form
    @method = method
    @collection = collection
    @value_method = value_method
    @text_method = text_method
    @options = options
    @label = label || I18n.t("common.select")
    @attrs = attrs.merge(default_attrs)
  end

  def template
    div(**@attrs) do
      render DropdownComponent.new do
        render DropdownComponent::Trigger.new do
          select(class: "w-full bg-white border border-gray-200 rounded-md px-3 py-2 flex items-center gap-x-1 justify-between", data_select_multiple_target: "button") do
            option(data_select_multiple_target: "label") { @label }
          end
        end

        render DropdownComponent::Content.new(data_select_multiple_target: "content") do
          div(class: "p-2") do
            div(class: "pb-1") do
              input type: "checkbox", class: "mr-2", id: "select-all", data: { action: "change->select-multiple#toggleAll", select_multiple_target: "selectAllCheckbox" }
              label(class: "font-bold", for: "select-all") { I18n.t("common.all") }
            end
            unsafe_raw (
              @form.collection_check_boxes @method, @collection, @value_method, @text_method, @options do |cb|
                div do
                  span(class: "mx-2") { cb.check_box class: "value-checkbox", data: { action: "change->select-multiple#updateAllCheckbox" } }
                  span { cb.label }
                end
              end
            )
          end
        end
      end
    end
  end

  def default_attrs
    {
      data: {
        controller: "select-multiple",
        select_multiple_label_value: @label
      }
    }
  end

  private
end
