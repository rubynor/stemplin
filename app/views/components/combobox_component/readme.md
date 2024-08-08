#### Quick example of how to use it
#### Reference https://phlexui-playground.fly.dev/phlex/combobox

````
      <%= render ComboboxComponent::Main do %>
        <%= render ComboboxComponent::Trigger.new(placeholder: "Select event...", aria_controls: "list") %>
        <%= render ComboboxComponent::Content.new(id: "list") do %>
          <%= render ComboboxComponent::SearchInput.new(placeholder: "Search event...") %>
          <%= render ComboboxComponent::List.new do %>
            <%= render ComboboxComponent::Empty.new { "No results found." } %>
            <%= render ComboboxComponent::Group.new(heading: "Suggestions") do %>
              <%= render ComboboxComponent::Item.new(value: "railsworld") do |item| %>
                <%= item.span { "Rails World" } %>
              <%= end %>
              <%= render ComboboxComponent::Item.new(value: "tropicalrb") do |item| %>
                <%= item.span { "Tropical.rb" } %>
              <%= end %>
              <%= render ComboboxComponent::Item.new(value: "friendly.rb") do |item| %>
                <%= item.span { "Friendly.rb" } %>
              <%= end %>
            <%= end %>

            <%= render ComboboxComponent::Separator.new %>

            <%= render ComboboxComponent::Group.new(heading: "Others") do %>
              <%= render ComboboxComponent::Item.new(value: "railsconf") do |item| %>
                <%= item.span { "RailsConf" } %>
              <%= end %>
              <%= render ComboboxComponent::Item.new(value: "euruko") do |item| %>
                <%= item.span { "Euruko" } %>
              <%= end %>
              <%= render ComboboxComponent::Item.new(value: "rubykaigi") do |item| %>
                <%= item.span { "RubyKaigi" } %>
              <%= end %>
            <%= end %>
          <%= end %>
        <%= end %>
      <%= end %>