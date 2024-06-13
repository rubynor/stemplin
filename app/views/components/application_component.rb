# frozen_string_literal: true

class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ContentTag
  include Phlex::Rails::Helpers::LabelTag
  include Phlex::Rails::Helpers::CheckboxTag
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::LinkTo

  def initialize(**user_attrs)
    @attrs = default_attrs.merge(user_attrs)
    @attrs[:class] = tokens(default_classes, user_attrs[:class])
  end

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end

  private

  def default_attrs
    {}
  end

  def default_classes
    ""
  end
end
