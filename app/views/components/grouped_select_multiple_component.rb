class GroupedSelectMultipleComponent < ApplicationComponent
  def initialize(form, method, grouped_objects, key_name_method, value_id_method, value_name_method, options = {}, label: nil, **attrs)
    @form = form
    @method = method
    @grouped_objects = grouped_objects
    @key_name_method = key_name_method
    @value_id_method = value_id_method
    @value_name_method = value_name_method
    @options = options
    @label = label || I18n.t("common.select")
    @attrs = attrs.merge(default_attrs)
  end

  def template
    div(**@attrs) do
      render DropdownComponent.new do
        render DropdownComponent::Trigger.new do
          select(class: "w-full bg-white border border-gray-200 rounded-md px-3 py-2 flex items-center gap-x-1 justify-between", data_grouped_select_multiple_target: "button") do
            option(data_grouped_select_multiple_target: "label") { @label }
          end
        end

        render DropdownComponent::Content.new(class: "w-full1", data_grouped_select_multiple_target: "content") do
          div(class: "p-2 divide-y divide-dashed") do
            div(class: "pb-1") do
              input type: "checkbox", class: "mr-2", id: "select-all", data: { action: "change->grouped-select-multiple#toggleAll", grouped_select_multiple_target: "selectAllCheckbox" }
              label(class: "font-bold", for: "select-all") { I18n.t("common.all") }
            end
            @grouped_objects.keys.each do |key|
              div(class: "group-div py-1") do
                input type: "checkbox", class: "mr-2 group-checkbox", id: "input_#{key[@key_name_method]}", data: { action: "change->grouped-select-multiple#toggleGroup" }
                label(class: "font-bold", for: "input_#{key[@key_name_method]}") { key[@key_name_method] }
                unsafe_raw (
                  @form.collection_check_boxes @method, @grouped_objects[key], @value_id_method, @value_name_method, @options do |cb|
                    div do
                      span(class: "mx-2") { cb.check_box class: "value-checkbox", data: { action: "change->grouped-select-multiple#updateAllAndGroupCheckboxes" } }
                      span { cb.label }
                    end
                  end
                )
              end
            end
          end
        end
      end
    end
  end

  def default_attrs
    {
      data: {
        controller: "grouped-select-multiple",
        grouped_select_multiple_label_value: @label
      }
    }
  end

  private
end
