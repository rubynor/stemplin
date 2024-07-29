# frozen_string_literal: true

class PaginationComponent < ApplicationComponent
  def initialize(**attrs)
    @attrs = attrs
    @tab = attrs[:tab]
    @pagy = attrs[:pagy]
    @path = attrs[:path]
  end

  def template(&content)
    render PhlexUI::Pagination.new(class: "py-4") do
      render PhlexUI::Pagination::Content.new(class: "text-primary") do
        render_link_to_first
        render_link_back_one

        render_link_to_prev
        render_link_to_current
        render_link_to_next

        render_link_forward
        render_link_to_last
      end
    end
  end

  private

  def render_link_to_first
    render PhlexUI::Pagination::Item.new(href: page_path(1), class: default_class) do
      content_tag(:i, "&#xe81a;".html_safe, class: "uc-icon text-xl")
    end
  end

  def render_link_back_one
    render PhlexUI::Pagination::Item.new(href: page_path(@pagy.prev), class: default_class) do
      content_tag(:i, "&#xe81e;".html_safe, class: "uc-icon text-xl")
    end
  end

  def render_link_to_prev
    render PhlexUI::Pagination::Item.new(href: page_path(@pagy.prev), class: default_class) { @pagy.prev } if @pagy.prev
  end

  def render_link_to_current
    render PhlexUI::Pagination::Item.new(href: page_path(@pagy.page), active: true, class: active_class) { @pagy.page }
  end

  def render_link_to_next
    render PhlexUI::Pagination::Item.new(href: page_path(@pagy.next), class: default_class) { @pagy.next } if @pagy.next
  end

  def render_link_forward
    render PhlexUI::Pagination::Item.new(href: page_path(@pagy.next), class: default_class) do
      content_tag(:i, "&#xe820;".html_safe, class: "uc-icon text-xl")
    end
  end

  def render_link_to_last
    render PhlexUI::Pagination::Item.new(href: page_path(@pagy.last), class: default_class) do
      content_tag(:i, "&#xe81b;".html_safe, class: "uc-icon text-xl")
    end
  end

  def active_class
    "bg-primary text-primary-foreground hover:bg-primary hover:text-primary-foreground"
  end

  def default_class
    "hover:bg-gray-100 hover:text-primary"
  end

  def page_path(page_number)
    uri = URI.parse(@path)
    query_hash = {}
    query_hash = query_hash.merge({ page: page_number })
    query_hash = query_hash.merge({ tab: @tab }) if @tab
    uri.query = query_hash.to_query
    uri.to_s
  end
end
