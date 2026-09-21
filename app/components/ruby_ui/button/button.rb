# frozen_string_literal: true

module RubyUI
  class Button < Base
    def initialize(type: :button, variant: :primary, size: :md, icon: false, **attrs)
      @type = type
      @variant = variant.to_sym
      @size = size.to_sym
      @icon = icon
      super(**attrs)
    end

    def view_template(&)
      button(**attrs, &)
    end

    private

    def size_classes
      if @icon
        case @size
        when :sm then "h-6 w-6"
        when :md then "h-10 w-10"
        when :lg then "h-10 w-10"
        when :xl then "h-12 w-12"
        end
      else
        case @size
        when :sm then "px-3 h-8 text-xs"
        when :md then "px-4 h-10 text-sm"
        when :lg then "px-5 h-11 text-sm"
        when :xl then "px-6 h-12 text-base"
        end
      end
    end

    def primary_classes
      [
        "whitespace-nowrap inline-flex items-center justify-center gap-x-2 rounded-lg font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/40 focus-visible:ring-offset-1 disabled:pointer-events-none disabled:opacity-50 bg-primary text-primary-foreground shadow-xs hover:bg-primary-700",
        size_classes
      ]
    end

    def link_classes
      [
        "whitespace-nowrap inline-flex items-center justify-center gap-x-2 rounded-lg font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/40 focus-visible:ring-offset-1 disabled:pointer-events-none disabled:opacity-50 text-primary underline-offset-4 hover:underline",
        size_classes
      ]
    end

    def secondary_classes
      [
        "whitespace-nowrap inline-flex items-center justify-center gap-x-2 rounded-lg font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/40 focus-visible:ring-offset-1 disabled:pointer-events-none disabled:opacity-50 bg-secondary text-secondary-foreground hover:bg-secondary/80",
        size_classes
      ]
    end

    def destructive_classes
      [
        "whitespace-nowrap inline-flex items-center justify-center gap-x-2 rounded-lg font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/40 focus-visible:ring-offset-1 disabled:pointer-events-none disabled:opacity-50 bg-destructive text-destructive-foreground hover:bg-red-100",
        size_classes
      ]
    end

    def outline_classes
      [
        "whitespace-nowrap inline-flex items-center justify-center gap-x-2 rounded-lg font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/40 focus-visible:ring-offset-1 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background shadow-xs hover:bg-accent hover:text-accent-foreground",
        size_classes
      ]
    end

    def ghost_classes
      [
        "whitespace-nowrap inline-flex items-center justify-center gap-x-2 rounded-lg font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/40 focus-visible:ring-offset-1 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground",
        size_classes
      ]
    end

    def default_classes
      case @variant
      when :primary then primary_classes
      when :link then link_classes
      when :secondary then secondary_classes
      when :destructive then destructive_classes
      when :outline then outline_classes
      when :ghost then ghost_classes
      end
    end

    def default_attrs
      {
        type: @type,
        class: default_classes
      }
    end
  end
end
