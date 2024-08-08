module ComboboxComponent
  class Bundler < ApplicationComponent

    def template
      render ComboboxComponent::Main do
        render ComboboxComponent::Trigger.new(placeholder: "Select event...", aria_controls: "list", size: :fill)
        render ComboboxComponent::Content.new(id: "list") do
          render ComboboxComponent::SearchInput.new(placeholder: "Search event...")
          render ComboboxComponent::List.new do
            render ComboboxComponent::Empty.new { "No results found." }
            render ComboboxComponent::Group.new(heading: "Suggestions") do
              render ComboboxComponent::Item.new(value: "railsworld") do |item|
                item.span { "Rails World" }
              end
              render ComboboxComponent::Item.new(value: "tropicalrb") do |item|
                item.span { "Tropical.rb" }
              end
              render ComboboxComponent::Item.new(value: "friendly.rb") do |item|
                item.span { "Friendly.rb" }
              end
            end
          end
        end
      end
    end
  end
end

