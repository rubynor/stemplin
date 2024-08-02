module SetCurrency
  extend ActiveSupport::Concern

  included do
    before_action :set_currency
  end

  private

  def set_currency
    @currency = current_user.current_organization.currency
  end
end
