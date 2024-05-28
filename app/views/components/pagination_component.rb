# frozen_string_literal: true

class PaginationComponent < ApplicationComponent
  def initialize(**attrs)
    @attrs = attrs
    @pagy = attrs[:pagy]
    @path = attrs[:path]
  end

  def template(&content)
    render PhlexUI::Pagination.new(class: "py-4") do
      render PhlexUI::Pagination::Content.new(class: "text-primary") do
        render PhlexUI::Pagination::Item.new(href: first_path, class: default_class) do
          content_tag(:i, "&#xe81a;".html_safe, class: "uc-icon text-xl")
        end
        render PhlexUI::Pagination::Item.new(href: prev_path, class: default_class) do
          content_tag(:i, "&#xe81e;".html_safe, class: "uc-icon text-xl")
        end

        render PhlexUI::Pagination::Item.new(href: prev_path, class: default_class) { @pagy.prev } if @pagy.prev
        render PhlexUI::Pagination::Item.new(href: current_path, active: true, class: active_class) { @pagy.page }
        render PhlexUI::Pagination::Item.new(href: next_path, class: default_class) { @pagy.next } if @pagy.next

        render PhlexUI::Pagination::Item.new(href: next_path, class: default_class) do
          content_tag(:i, "&#xe820;".html_safe, class: "uc-icon text-xl")
        end
        render PhlexUI::Pagination::Item.new(href: last_path, class: default_class) do
          content_tag(:i, "&#xe81b;".html_safe, class: "uc-icon text-xl")
        end
      end
    end
  end

  private

  def active_class
    "bg-primary text-primary-foreground hover:bg-primary hover:text-primary-foreground"
  end

  def default_class
    "hover:bg-gray-100 hover:text-primary"
  end

  def current_path
    page_path(@pagy.page)
  end

  def prev_path
    page_path(@pagy.prev)
  end

  def next_path
    page_path(@pagy.next)
  end

  def first_path
    page_path(1)
  end

  def last_path
    page_path(@pagy.last)
  end

  def page_path(page_number)
    uri = URI.parse(@path)
    uri.query = { page: page_number }.to_query
    uri.to_s
  end
end
