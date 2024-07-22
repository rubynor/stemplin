class GroupedSelectMultipleComponent < ApplicationComponent
  def initialize(form, method, grouped_objects, key_name_method, value_id_method, value_name_method, options = {}, label: nil, id: nil, **attrs)
    @form = form
    @method = method
    @grouped_objects = grouped_objects
    @key_name_method = key_name_method
    @value_id_method = value_id_method
    @value_name_method = value_name_method
    @options = options
    @label = label || I18n.t("common.select")
    @attrs = attrs.merge(default_attrs)
    @id = id || SecureRandom.hex(5)
  end

  def template
    div(**@attrs) do
      render DropdownComponent.new do
        render DropdownComponent::Trigger.new do
          select(class: "w-full bg-white border border-gray-200 rounded-md px-3 py-2 flex items-center gap-x-1 justify-between", data_grouped_select_multiple_target: "button") do
            option(data_grouped_select_multiple_target: "label") { @label }
          end
        end

        render DropdownComponent::Content.new(class: "w-full", data_grouped_select_multiple_target: "content") do
          div(class: "p-2 divide-y divide-dashed") do
            div(class: "mb-1 hover:bg-slate-100 flex items-center") do
              input type: "checkbox", class: "mr-2", id: "select-all-#{@id}", data: { action: "change->grouped-select-multiple#toggleAll", grouped_select_multiple_target: "selectAllCheckbox" }
              label(class: "font-bold block w-full", for: "select-all-#{@id}") { I18n.t("common.all") }
            end
            @grouped_objects.keys.each do |key|
              div(class: "group-div py-1") do
                div(class: "hover:bg-slate-100 flex items-center") do
                  input type: "checkbox", class: "mr-2 group-checkbox", id: "input-#{key[@key_name_method]}-#{@id}", data: { action: "change->grouped-select-multiple#toggleGroup" }
                  label(class: "font-bold block w-full", for: "input-#{key[@key_name_method]}-#{@id}") { key[@key_name_method] }
                end
                unsafe_raw (
                  @form.collection_check_boxes @method, @grouped_objects[key], @value_id_method, @value_name_method, @options do |cb|
                    div(class: "hover:bg-slate-100 flex items-center") do
                      span(class: "mx-2") { cb.check_box class: "value-checkbox", data: { action: "change->grouped-select-multiple#updateAllAndGroupCheckboxes" } }
                      span(class: "w-full") { cb.label(class: "block w-full") }
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
