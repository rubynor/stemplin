module Tripletex
  # Sends time registrations to Tripletex as one order per client, with one order line per
  # project + task (hours summed, priced at the task rate or else the project rate).
  # The detailed report for those hours is attached as a PDF that goes out with the invoice.
  # Sent registrations get `invoiced_at`, so sending the same report again skips them.
  class CreateOrders
    Result = Struct.new(:orders, :skipped_clients, :errors, :warnings, keyword_init: true) do
      def minutes = orders.sum { |order| order[:minutes] }
    end

    # Only billable, finished, not yet invoiced time on the organization's own clients
    # (time on projects shared with us belongs to another organization's invoicing).
    def self.invoiceable(time_regs, organization)
      time_regs.not_invoiced.where(start_time: nil).where.not(minutes: 0).where(
        assigned_task: AssignedTask.joins(project: :client).where(projects: { billable: true }, clients: { organization_id: organization.id })
      )
    end

    def initialize(organization:, time_regs:, api: organization.tripletex_integration&.api)
      @organization = organization
      @time_regs = time_regs
      @api = api
    end

    def call
      result = Result.new(orders: [], skipped_clients: [], errors: [], warnings: [])
      raise Error, I18n.t("tripletex.errors.not_connected") unless @api

      regs_by_client = self.class.invoiceable(@time_regs, @organization)
                                 .includes(assigned_task: { project: :client })
                                 .group_by { |reg| reg.assigned_task.project.client }

      regs_by_client.sort_by { |client, _| client.name.downcase }.each do |client, regs|
        if client.tripletex_customer_id.blank?
          result.skipped_clients << client
        else
          send_order(client, regs.map(&:id), result)
        end
      end
      result
    end

    private

    def send_order(client, time_reg_ids, result)
      TimeReg.transaction do
        # Re-read under a row lock so a double submit can't put the same hours on two orders.
        regs = TimeReg.not_invoiced.where(id: time_reg_ids).lock.includes(:project, :task, :user, assigned_task: %i[project task]).to_a
        next if regs.empty?

        report = ReportPdf.new(organization: @organization, client: client, time_regs: regs)
        pdf = report.render
        order_id = @api.create_order(order_attributes(client, regs))
        now = Time.current
        TimeReg.where(id: regs.map(&:id)).update_all(invoiced_at: now, tripletex_order_id: order_id, updated_at: now)
        result.orders << { client: client, order_id: order_id, minutes: regs.sum(&:minutes) }
        attach_report(client, order_id, report.filename, pdf, result)
      end
    rescue Error => e
      result.errors << "#{client.name}: #{e.message}"
    end

    # The order already exists at this point, so a failed upload must not undo the invoicing.
    def attach_report(client, order_id, filename, pdf, result)
      @api.attach_to_order(order_id, filename: filename, data: pdf)
    rescue Error => e
      result.warnings << I18n.t("tripletex.reports.attachment_failed", client: client.name, order: order_id, message: e.message)
    end

    def order_attributes(client, regs)
      dates = regs.map(&:date_worked)
      {
        customer: { id: client.tripletex_customer_id },
        orderDate: Date.current.iso8601,
        deliveryDate: dates.max.iso8601,
        invoiceComment: I18n.t("tripletex.order.comment", from: dates.min.strftime("%d.%m.%Y"), to: dates.max.strftime("%d.%m.%Y")),
        orderLines: order_lines(regs)
      }
    end

    def order_lines(regs)
      regs.group_by(&:assigned_task)
          .sort_by { |assigned_task, _| [ assigned_task.project.name.downcase, assigned_task.task.name.downcase ] }
          .map do |assigned_task, task_regs|
            {
              description: "#{assigned_task.project.name} – #{assigned_task.task.name}",
              count: (task_regs.sum(&:minutes) / 60.0).round(2),
              unitPriceExcludingVatCurrency: task_regs.first.used_rate / 100.0
            }
          end
    end
  end
end
