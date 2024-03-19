module Dialog
  class Header < ViewComponent::Base
    def initialize(title:, subtitle: nil)
      @title = title
      @subtitle = subtitle
    end

    attr_reader :title, :subtitle
  end
end
