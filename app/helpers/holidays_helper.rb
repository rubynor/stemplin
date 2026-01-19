module HolidaysHelper
  def holidays_for_country(country_code)
    return [] unless valid_country_code?(country_code)

    start_date = Date.today
    end_date = start_date + 1.year

    Holidays.between(start_date, end_date, country_code.to_sym)
      .sort_by { |holiday| holiday[:date] }
  end

  def format_holiday_date(date)
    date.strftime("%A, %B %d, %Y")
  end

  def country_name_from_code(code)
    countries = Stemplin.config.countries || {}
    countries[code.to_sym] || code.to_s.upcase
  end

  def for_select_countries(country_codes)
    country_codes.map { |code| [ country_name_from_code(code), code.to_s ] }
  end

  private

  def valid_country_code?(code)
    Holidays.available_regions.include?(code.to_sym)
  end
end
