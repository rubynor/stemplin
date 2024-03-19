module Dialog
  class Base < ViewComponent::Base
    include Helpers

    renders_one :show_button, ->(label:, classes: nil) do
      button_tag(label, type: :button, class: class_names(call_to_action_class_names, classes), data: dialog_button_actions)
    end

    renders_one :header, -> do
      Dialog::Header.new(title: @title, subtitle: @subtitle)
    end

    renders_one :body, "Dialog::Body"
    renders_one :footer, "Dialog::Footer"

    def initialize(title:, subtitle: nil, text: nil, id: "dialog-#{rand(36**4).to_s(36)}", open: false, allow_close: true, size: nil)
      @id = id.to_s
      @title = title
      @subtitle = subtitle
      @text = text
      @open = open
      @allow_close = allow_close
      @size = size
    end

    attr_reader :id, :title, :subtitle, :text, :open, :allow_close, :size

    def before_render
      with_header unless header?

      if text?
        with_body { text_content }
      end
    end

    def wrapper_options
      wrapper_options = { class: "dialog-wrapper" }
      data = {}

      data[:controller] = token_list({bridge_controller => @use_bridge_controller}, stimulus_controller)
      data[:dialog_open_value] = open.to_s
      wrapper_options[:data] = data

      wrapper_options
    end

    def backdrop_options
      backdrop_options = { id: id, class: class_names("dialog-backdrop", hidden: !open) }
      data = { dialog_target: :backdrop }

      data[:action] = "click@window->#{stimulus_controller}#closeBackground" if close_on_background_click?
      backdrop_options[:data] = data

      backdrop_options
    end

    def dialog_button_actions
      @dialog_button_actions ||= { action: "click->#{stimulus_controller}#toggle" }
    end

    def modal_size
      case @size
      when "lg"
        "max-w-lg"
      when "xl"
        "max-w-xl"
      when "2xl"
        "max-w-2xl"
      else
        "max-w-md"
      end
    end

    def allow_close?
      allow_close
    end

    def close_on_background_click?
      allow_close?
    end

    def text?
      @text.present?
    end

    def text_content
      simple_format(text)
    end
  end
end
