require "test_helper"

module Tripletex
  class ReportPdfTest < ActiveSupport::TestCase
    setup do
      @regs = TimeReg.joins(project: :client).where(clients: { id: clients(:e_corp).id }).includes(:project, :task, :user, :assigned_task).to_a
    end

    def report = ReportPdf.new(organization: organizations(:organization_one), client: clients(:e_corp), time_regs: @regs)

    test "renders a PDF named after the client and period" do
      dates = @regs.map(&:date_worked)

      assert report.render.start_with?("%PDF")
      assert_equal "e-corp-#{dates.min.iso8601}-#{dates.max.iso8601}.pdf", report.filename
    end

    test "copes with characters the PDF font cannot draw" do
      @regs.first.notes = "Møte med 李 🚀 & <kunde>"
      @regs.first.user.first_name = "Ærlig"

      assert report.render.start_with?("%PDF")
    end
  end
end
