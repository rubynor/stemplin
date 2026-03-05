# frozen_string_literal: true

require "tailwind_merge"

class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::ContentTag
  include Phlex::Rails::Helpers::LabelTag
  include Phlex::Rails::Helpers::CheckBoxTag
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::CollectionSelect
  include Phlex::Rails::Helpers::HiddenField
  include Phlex::Rails::Helpers::HiddenFieldTag
  include Phlex::Rails::Helpers::FieldsFor
  include Phlex::Rails::Helpers::FormTag

  TAILWIND_MERGER = ::TailwindMerge::Merger.new.freeze unless defined?(TAILWIND_MERGER)

  def initialize(**attrs)
    @attrs = default_attrs.merge(attrs)
    @attrs[:class] = TAILWIND_MERGER.merge([ default_classes, attrs[:class], @attrs[:class]&.split(" ") ])
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
