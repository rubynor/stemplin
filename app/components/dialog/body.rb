module Dialog
  class Body < ViewComponent::Base
    def call
      content_tag(:div, content, class: "dialog-body-wrapper")
    end
  end
end
