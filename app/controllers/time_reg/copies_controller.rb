# frozen_string_literal: true

class TimeReg::CopiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_time_reg

  def create
    authorize! @time_reg
    target_dates = parse_target_dates

    target_dates.each do |target_date|
      new_time_reg = @time_reg.dup
      new_time_reg.date_worked = target_date
      new_time_reg.start_time = nil
      new_time_reg.save
    end

    redirect_to time_regs_path(date: target_dates.last || @time_reg.date_worked)
  end

  private

  def set_time_reg
    @time_reg = TimeReg.find(params[:time_reg_id])
  end

  def parse_target_dates
    if params[:dates].present?
      params[:dates].map { |d| Date.parse(d) }
    elsif params[:date].present?
      [ Date.parse(params[:date]) ]
    else
      [ Date.today ]
    end
  end
end
