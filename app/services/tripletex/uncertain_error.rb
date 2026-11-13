module Tripletex
  # A write (POST/PUT/DELETE) failed after it may have reached Tripletex, so it may or may not have taken effect.
  class UncertainError < Error; end
end
