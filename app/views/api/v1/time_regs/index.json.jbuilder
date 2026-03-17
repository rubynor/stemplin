json.time_regs @time_regs, partial: "api/v1/time_regs/time_reg", as: :time_reg

json.pagination do
  json.current_page @pagy.page
  json.total_pages @pagy.pages
  json.total_count @pagy.count
end
