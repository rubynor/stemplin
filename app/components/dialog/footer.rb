module Dialog
  class Footer < ViewComponent::Base
    def call
      content_tag(:div, content, class: "dialog-footer-wrapper flex w-full justify-center items-center")
    end
  end
end
