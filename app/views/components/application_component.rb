# frozen_string_literal: true

class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ContentTag
  include Phlex::Rails::Helpers::LabelTag
  include Phlex::Rails::Helpers::CheckboxTag
  include Phlex::Rails::Helpers::ImageTag

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
