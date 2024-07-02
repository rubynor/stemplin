module Deletable
  extend ActiveSupport::Concern

  included do
    include Discard::Model
    default_scope -> { kept }
    # Documentation says that ```It's usually undesirable to add a default scope.
    # It will take more effort to work around and will cause more headaches.
    # If you know you need a default scope, it's easy to add yourself ❤```.
    # https://github.com/jhawthorn/discard?tab=readme-ov-file#default-scope

    # Let's come back to this if it really becomes an issue
    # scope :active, -> { where(discarded_at: nil) }
  end
end
