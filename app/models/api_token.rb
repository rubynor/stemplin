# A personal access token for the API, the CLI and the MCP tools. A user can
# hold several, each with a label of their own choosing.
#
# Only the SHA-256 digest is stored. The plaintext exists on the instance that
# just generated it and nowhere else, so it can be shown once and never again.
class ApiToken < ApplicationRecord
  belongs_to :user

  attr_reader :plaintext

  validates :name, presence: true, length: { maximum: 60 }

  before_create :generate

  def self.find_by_plaintext(plaintext)
    return nil if plaintext.blank?

    find_by(token_digest: digest(plaintext))
  end

  def self.digest(plaintext)
    Digest::SHA256.hexdigest(plaintext)
  end

  # Swaps the secret in place and returns the new one. The label stays, and
  # the old secret stops working.
  def regenerate!
    generate
    save!
    plaintext
  end

  private

  def generate
    @plaintext = SecureRandom.base58(24)
    self.token_digest = self.class.digest(@plaintext)
  end
end
