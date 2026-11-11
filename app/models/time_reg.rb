class TimeReg < ApplicationRecord
  include Deletable

  MINUTES_IN_A_DAY = 1.day.in_minutes.to_i

  has_paper_trail
  belongs_to :user
  belongs_to :assigned_task
  broadcasts_refreshes

  has_one :project, through: :assigned_task
  has_one :task, through: :assigned_task, source: :task
  has_one :client, through: :project
  has_one :organization, through: :project

  before_validation :start, if: -> { minutes.zero? && date_worked == Date.today }, on: :create

  validates :notes, length: { maximum: 10000 }
  validates :minutes, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1440 }
  validates :date_worked, presence: true

  validate :only_one_active_time_reg
  validate :month_not_locked

  before_discard :prevent_change_in_locked_month
  before_destroy :prevent_change_in_locked_month

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
  # Ignores soft-deletes on project and client, so entries on deleted projects stay attributable.
  scope :in_organization, ->(organization_id) {
    where(assigned_task_id: AssignedTask.unscoped
      .joins("INNER JOIN projects ON projects.id = assigned_tasks.project_id " \
             "INNER JOIN clients ON clients.id = projects.client_id")
      .where(clients: { organization_id: organization_id }).select(:id))
  }
  scope :billable, -> { joins(:project).where(projects: { billable: true }) }

  scope :by_clients, ->(client_ids) { joins(project: :client).where(clients: { id: client_ids }) }
  scope :by_projects, ->(project_ids) { where(assigned_task: AssignedTask.where(project_id: project_ids)) }
  scope :by_users, ->(user_ids) { where(user_id: user_ids) }
  scope :by_tasks, ->(task_ids) { where(assigned_task: AssignedTask.where(task_id: task_ids)) }

  def active?
    start_time.present?
  end

  def is_zero_minutes?
    minutes.zero? && !active?
  end

  def toggle_active
    active? ? stop : start
    save!
  end

  def stop
    worked_minutes = (Time.now.to_i - start_time.to_i) / 60
    self.minutes = [ minutes + worked_minutes, MINUTES_IN_A_DAY ].min
    self.start_time = nil
  end

  def start
    return false if date_worked != Date.today
    self.start_time = Time.now
  end

  def current_minutes
    return self.minutes unless self.active?
    self.minutes + (Time.now - self.start_time).seconds.in_minutes.to_i
  end

  def used_rate
    assigned_task.rate.positive? ? assigned_task.rate : project.rate
  end

  def total_hours
    minutes.to_f / 60
    # TODO: ensure the hours used in calculations is the same as hours displayed check `minutes_to_float`
  end

  def billed_amount
    total_hours * used_rate
  end

  # The organization through assigned task, project and client, ignoring soft-deletes.
  def organization_id_for_lock
    organization_id_for_assigned_task(assigned_task_id)
  end

  protected

  def organization_id_for_assigned_task(id)
    return if id.nil?

    Client.unscoped
          .joins("INNER JOIN projects ON projects.client_id = clients.id " \
                 "INNER JOIN assigned_tasks ON assigned_tasks.project_id = projects.id")
          .where(assigned_tasks: { id: id })
          .pick(:organization_id)
  end

  # The first locked month this change touches: the entry's current date and, when
  # it already exists, the date and assigned task it was saved with.
  def locked_date
    dates = [ date_worked ]
    organization_ids = [ organization_id_for_lock ]
    if persisted?
      dates << date_worked_in_database
      organization_ids << organization_id_for_assigned_task(assigned_task_id_in_database)
    end
    organization_ids.compact.uniq.product(dates.compact.uniq).find do |organization_id, date|
      TimeLock.locked?(organization_id: organization_id, user_id: user_id, date: date)
    end&.last
  end

  def add_month_locked_error
    date = locked_date
    return false unless date

    errors.add(:base, I18n.t("tripletex.locks.errors.month_locked", month: I18n.l(date, format: "%B %Y")))
    true
  end

  def month_not_locked
    add_month_locked_error
  end

  def prevent_change_in_locked_month
    throw :abort if add_month_locked_error
  end

  def only_one_active_time_reg
    active_time_regs = self.user.time_regs.all_active
    if persisted?
      active_time_regs = active_time_regs.where.not(id: id)
    end
    if active_time_regs.exists? && self.active?
      errors.add(:base, I18n.t("time_reg.errors.messages.timer_running"))
    end
  end
end
