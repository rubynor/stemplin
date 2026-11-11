require "prawn"
require "prawn/table"

Prawn::Fonts::AFM.hide_m17n_warning = true

module Tripletex
  # The detailed report for the hours on one Tripletex order, as a PDF to attach to that order.
  # Mirrors the detailed report page: entries grouped by day, with daily and grand totals.
  class ReportPdf
    MUTED = "71717A".freeze
    LINE = "E8E8EC".freeze
    SHADE = "F4F4F5".freeze

    def initialize(organization:, client:, time_regs:, printed_at: Time.current)
      @organization = organization
      @client = client
      @time_regs = time_regs.sort_by { |reg| [ reg.date_worked, reg.created_at ] }
      @printed_at = printed_at
    end

    def filename
      dates = @time_regs.map(&:date_worked)
      "#{@client.name.parameterize}-#{dates.min.iso8601}-#{dates.max.iso8601}.pdf"
    end

    def render
      pdf = Prawn::Document.new(page_size: "A4", margin: [ 40, 34, 48, 34 ], info: { Title: text(title), Creator: "Stemplin" })
      pdf.font_size 9
      header(pdf)
      summary(pdf)
      entries(pdf)
      page_numbers(pdf)
      pdf.render
    end

    private

    def title
      "#{I18n.t('common.report')} · #{@organization.name}"
    end

    def header(pdf)
      dates = @time_regs.map(&:date_worked)
      top = pdf.cursor
      pdf.text text(title), size: 15, style: :bold
      pdf.move_down 4
      pdf.text text("#{I18n.t('common.client')}: #{@client.name}"), color: MUTED
      pdf.text text("#{I18n.t('tripletex.print.period')}: #{date(dates.min)} – #{date(dates.max)}"), color: MUTED
      pdf.text_box text(I18n.t("tripletex.print.printed_at", time: @printed_at.strftime("%d.%m.%Y %H:%M"))),
                   at: [ 0, top ], width: pdf.bounds.width, align: :right, color: MUTED
      pdf.move_down 8
      pdf.stroke_color "18181B"
      pdf.stroke_horizontal_rule
      pdf.move_down 12
    end

    def summary(pdf)
      billable = @time_regs.select { |reg| reg.project.billable }.sum(&:minutes)
      pdf.table([ [ I18n.t("common.total_hours"), I18n.t("common.total_billable_hours") ].map { |label| text(label) },
                  [ hours(@time_regs.sum(&:minutes)), hours(billable) ] ],
                cell_style: { borders: [], padding: [ 0, 24, 2, 0 ] }) do |table|
        table.row(0).text_color = MUTED
        table.row(1).size = 14
        table.row(1).font_style = :bold
      end
      pdf.move_down 16
    end

    def entries(pdf)
      head = [ I18n.t("common.project"), I18n.t("common.task"), I18n.t("common.person"), I18n.t("common.rate"), I18n.t("common.hours") ]
      rows = [ head.map { |label| escape(label.upcase) } ]
      day_rows = []

      @time_regs.group_by(&:date_worked).each do |day, regs|
        day_rows << rows.size
        rows << [ { content: date(day), colspan: 4 }, hours(regs.sum(&:minutes)) ]
        regs.each do |reg|
          task = escape(reg.task.name)
          task += "\n<color rgb='#{MUTED}'><font size='7.5'>#{escape(reg.notes.strip)}</font></color>" if reg.notes.present?
          rows << [ escape(reg.project.name), task, escape(reg.user.name),
                    "#{@organization.currency} #{format('%.2f', reg.used_rate / 100.0)}", hours(reg.minutes) ]
        end
      end
      rows << [ { content: escape(I18n.t("common.total")), colspan: 4 }, hours(@time_regs.sum(&:minutes)) ]

      pdf.table(rows, header: true, width: pdf.bounds.width, column_widths: { 0 => 100, 2 => 90, 3 => 70, 4 => 45 },
                cell_style: { borders: [ :bottom ], border_color: LINE, padding: [ 5, 4 ], inline_format: true }) do |table|
        table.row(0).font_style = :bold
        table.row(0).size = 7.5
        table.row(0).text_color = MUTED
        table.row(0).background_color = SHADE
        day_rows.each do |index|
          table.row(index).font_style = :bold
          table.row(index).background_color = SHADE
        end
        table.row(-1).font_style = :bold
        table.row(-1).borders = [ :top ]
        table.row(-1).border_color = "18181B"
        table.column(3..4).align = :right
      end
    end

    def page_numbers(pdf)
      pdf.number_pages text("<page> / <total>"), at: [ 0, -18 ], width: pdf.bounds.width, align: :right, size: 7.5, color: MUTED
    end

    def hours(minutes)
      format("%.2f", minutes / 60.0)
    end

    def date(day)
      day.strftime("%d.%m.%Y")
    end

    # Prawn's built-in fonts are Windows-1252; anything outside it (emoji, other scripts) becomes "?".
    def text(value)
      value.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
    end

    def escape(value)
      ERB::Util.html_escape(text(value)).to_str
    end
  end
end
