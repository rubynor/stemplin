# Spreadsheets run a cell that starts with one of these as a formula. Text that
# people typed in (notes, names) is prefixed with a quote so it stays text.
module CsvSafe
  FORMULA_START = /\A[=+\-@\t\r]/

  def self.row(values)
    values.map { |value| cell(value) }
  end

  def self.cell(value)
    value.is_a?(String) && value.match?(FORMULA_START) ? "'#{value}" : value
  end
end
