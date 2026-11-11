module Payroll
  # Read model for the payroll page: one row per team member for one month.
  # The caller authorizes; this object only needs the organization.
  class Overview
    Row = Data.define(:user, :access_info, :minutes, :hours, :rate, :amount, :status, :lock, :payout)

    attr_reader :error

    def initialize(organization:, period:)
      @organization = organization
      @period = period.to_date.beginning_of_month
    end

    def rows
      @rows ||= build_rows
    end

    private

    def build_rows
      access_infos = relevant_access_infos
      minutes = minutes_by_user
      locks = TimeLock.where(organization_id: @organization.id).for_period(@period).index_by(&:user_id)
      pay = pay_details(access_infos.filter_map(&:tripletex_employee_id))

      access_infos.sort_by { |info| sort_key(info.user) }.map do |info|
        build_row(info, minutes.fetch(info.user_id, 0), locks[info.user_id], pay)
      end
    end

    def build_row(info, minutes, lock, pay)
      payout = payout_for(info.user)
      rule = PayRules.for(pay[info.tripletex_employee_id]) if info.tripletex_employee_id
      status = status_for(payout:, minutes:, info:, lock:, rule:)

      if payout && %i[sent unclear].include?(status)
        hours, rate, amount = payout.hours, payout.rate, payout.amount
      else
        hours = (minutes / 60.0).round(2).to_d
        rate = rule&.rate
        amount = rule&.amount(minutes)
      end

      Row.new(user: info.user, access_info: info, minutes:, hours:, rate:, amount:, status:, lock:, payout:)
    end

    def status_for(payout:, minutes:, info:, lock:, rule:)
      if payout&.status == "sent" then :sent
      elsif %w[unclear pending].include?(payout&.status) then :unclear
      elsif minutes.zero? then :no_hours
      elsif info.tripletex_employee_id.nil? then :not_linked
      elsif lock.nil? then :not_locked
      elsif rule.nil? then :unsupported
      else :ready
      end
    end

    # Active non-spectator members, plus anyone (archived or spectator) with hours that month.
    def relevant_access_infos
      infos = AccessInfo.where(organization_id: @organization.id).includes(:user)
      with_hours = minutes_by_user.keys
      infos.unarchived.plannable.or(infos.where(user_id: with_hours)).to_a
    end

    # One query for everyone; includes entries on soft-deleted projects and clients.
    def minutes_by_user
      @minutes_by_user ||= TimeReg.in_organization(@organization.id)
                                  .where(date_worked: @period..@period.end_of_month)
                                  .group(:user_id).sum(:minutes)
    end

    # Tripletex failures leave hours visible but give no rates.
    def pay_details(employee_ids)
      return {} if employee_ids.empty?

      @organization.tripletex_integration.api.pay_details(employee_ids, on: @period.end_of_month)
    rescue Tripletex::Error => e
      @error = e.message
      {}
    end

    # Replaced when payouts exist.
    def payout_for(_user)
      nil
    end

    def sort_key(user)
      [ (user.name.presence || user.email).to_s.downcase, user.id ]
    end
  end
end
