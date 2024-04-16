# frozen_string_literal: true

class SwitchComponent < ApplicationComponent
  def initialize(form:, attribute:, initial_value:)
    @form = form
    @attribute = attribute
    @initial_value = initial_value
  end

  def template
    label_tag(@attribute, class: "relative inline-flex items-center cursor-pointer") do
      check_box_tag(@attribute, 1, @initial_value, { class: "h-6 w-6 sr-only peer" })
      div(class: "group peer ring-0 bg-gray-400  rounded-full outline-none duration-300 after:duration-300 w-16 h-8  shadow-md peer-checked:bg-purple-600  peer-focus:outline-none  after:content-['✖️']  after:rounded-full after:absolute after:bg-gray-50 after:outline-none after:h-6 after:w-6 after:top-1 after:left-1 after:flex after:justify-center after:items-center peer-checked:after:translate-x-8 peer-checked:after:content-['✔️'] peer-hover:after:scale-95")
    end
  end
end
