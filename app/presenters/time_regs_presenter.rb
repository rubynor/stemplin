class TimeRegsPresenter
  def initialize(time_regs)
    @time_regs = time_regs
  end

  def as_hashes
    @time_regs.map { |time_reg| TimeRegPresenter.new(time_reg).as_hash }
  end

  def report_data(title:, keys:)
    {
      title: title,
      children: time_reg_report(as_hashes, keys),
      total: as_hashes.sum { |time_reg| time_reg[:minutes] }
    }
  end

  def time_reg_report(time_regs, keys)
    key = keys.first

    return [] if key.blank?

    grouped_regs = time_regs.group_by { |time_reg| time_reg[key] }

    grouped_regs.map do |group, regs|
      {
        title: group,
        key: key,
        children: time_reg_report(regs, keys[1..]),
        minutes: regs.sum { |reg| reg[:minutes] }
      }
    end
  end
end
