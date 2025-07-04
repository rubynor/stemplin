# frozen_string_literal: true

module RubyUI
  class BreadcrumbLink < Base
    def initialize(href: "#", **attrs)
      @href = href
      super(**attrs)
    end

    def view_template(&)
      a(href: @href, **attrs, &)
    end

    private

    def default_attrs
      {
        class: "whitespace-nowrap inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 text-primary-600 underline-offset-4 hover:underline"
      }
    end
  end
end
