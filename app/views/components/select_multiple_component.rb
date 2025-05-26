class SelectMultipleComponent < ApplicationComponent
  def initialize(form, method, collection, value_method, text_method, options = {}, label: nil, **attrs)
    @form = form
    @method = method
    @collection = collection
    @value_method = value_method
    @text_method = text_method
    @options = options
    @label = label || I18n.t("common.select")
    @attrs = attrs.merge(default_attrs)
    @id = SecureRandom.hex(5)
  end

  def view_template
    div(**@attrs) do
      render DropdownComponent.new do
        render DropdownComponentTrigger.new do
          select(class: "w-full bg-white border border-gray-200 rounded-md px-3 py-2 flex items-center gap-x-1 justify-between", data_select_multiple_target: "button") do
            option(data_select_multiple_target: "label") { @label }
          end
        end

        render DropdownComponentContent.new(class: "w-full", data_select_multiple_target: "content") do
          div(class: "p-2") do
            div(class: "mb-1 hover:bg-slate-100 flex items-center") do
              input type: "checkbox", class: "mr-2", id: "select-all-#{@id}", data: { action: "change->select-multiple#toggleAll", select_multiple_target: "selectAllCheckbox" }
              label(class: "font-bold block w-full", for: "select-all-#{@id}") { I18n.t("common.all") }
            end
            raw (
              @form.collection_check_boxes @method, @collection, @value_method, @text_method, @options do |cb|
                div(class: "hover:bg-slate-100 flex items-center") do
                  span(class: "mx-2") { cb.check_box class: "value-checkbox", data: { action: "change->select-multiple#updateAllCheckbox" } }
                  span(class: "w-full") { cb.label(class: "block w-full") }
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
