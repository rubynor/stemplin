class TimeReg < ApplicationRecord
  MINUTES_IN_A_DAY = 1.day.in_minutes.to_i

  validates :notes, format: { without: /\r|\n/, message: "Line breaks are not allowed" }

  belongs_to :user
  belongs_to :assigned_task

  has_one :project, through: :assigned_task
  has_one :task, through: :assigned_task, source: :task
  has_one :client, through: :project
  has_one :organization, through: :project

  validates :notes, length: { maximum: 255 }
  validates :minutes, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }
  validates :assigned_task, presence: true
  validates :assigned_task_id, presence: true
  validates :date_worked, presence: true
  validate :only_one_active_time_reg

  before_create :set_start_time, if: -> { minutes.zero? && date_worked == Date.today }

  scope :for_report, ->(client_ids, project_ids, user_ids, task_ids) {
    joins(:user, :project, :task, :client)
      .where(
        client: { id: client_ids },
        project: { id: project_ids },
        user: { id: user_ids },
        task: { id: task_ids },
      )
  }
  scope :on_date, ->(given_date) {
    where("date(date_worked) = ?", given_date).includes(:project, :assigned_task).order(created_at: :desc)
  }
  scope :between_dates, ->(start_date, end_date) {
    where("date(date_worked) BETWEEN ? AND ?", start_date, end_date)
  }
  scope :all_active, -> { where.not(start_time: nil) }

  def active?
    start_time.present?
  end

  def toggle_active
    if active?
      worked_minutes = (Time.now.to_i - start_time.to_i) / 60
      self.minutes = [ minutes + worked_minutes, MINUTES_IN_A_DAY ].min
      self.start_time = nil
    else
      self.start_time = Time.now
    end

    save!
  end

  scope :for_report, ->(client_ids, project_ids, user_ids, task_ids) {
    joins(:user, :project, :task, :client)
      .where(
        client: { id: client_ids },
        project: { id: project_ids },
        user: { id: user_ids },
        task: { id: task_ids },
      )
  }

  scope :on_date, ->(given_date) {
    where("date(date_worked) = ?", given_date).includes(:project, :assigned_task).order(created_at: :desc)
  }

  scope :between_dates, ->(start_date, end_date) {
    where("date(date_worked) BETWEEN ? AND ?", start_date, end_date)
  }

  protected

  def only_one_active_time_reg

    active_time_regs = self.user.time_regs.where.not(start_time: nil)
    if persisted?
      active_time_regs = active_time_regs.where.not(id: id)
    end
    if active_time_regs.exists? && minutes.zero?
      errors.add(:base, I18n.t("time_reg.errors.messages.timer_running"))
    end
  end

  private

  def set_start_time
    self.start_time ||= Time.now
  end
end
