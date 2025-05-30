# frozen_string_literal: true

class PaginationComponent < ApplicationComponent
  def initialize(**attrs)
    @attrs = attrs
    @params = attrs[:params] || {}
    @pagy = attrs[:pagy]
    @path = attrs[:path]
  end

  def view_template(&content)
    render RubyUI::Pagination.new(class: "py-4") do
      render RubyUI::PaginationContent.new(class: "text-primary-600") do
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
    render RubyUI::PaginationItem.new(href: page_path(1), class: default_class) do
      content_tag(:i, "&#xe81a;".html_safe, class: "uc-icon text-xl")
    end
  end

  def render_link_back_one
    render RubyUI::PaginationItem.new(href: page_path(@pagy.prev), class: default_class) do
      content_tag(:i, "&#xe81e;".html_safe, class: "uc-icon text-xl")
    end
  end

  def render_link_to_prev
    render RubyUI::PaginationItem.new(href: page_path(@pagy.prev), class: default_class) { @pagy.prev } if @pagy.prev
  end

  def render_link_to_current
    render RubyUI::PaginationItem.new(href: page_path(@pagy.page), active: true, class: active_class) { @pagy.page }
  end

  def render_link_to_next
    render RubyUI::PaginationItem.new(href: page_path(@pagy.next), class: default_class) { @pagy.next } if @pagy.next
  end

  def render_link_forward
    render RubyUI::PaginationItem.new(href: page_path(@pagy.next), class: default_class) do
      content_tag(:i, "&#xe820;".html_safe, class: "uc-icon text-xl")
    end
  end

  def render_link_to_last
    render RubyUI::PaginationItem.new(href: page_path(@pagy.last), class: default_class) do
      content_tag(:i, "&#xe81b;".html_safe, class: "uc-icon text-xl")
    end
  end

  def active_class
    "bg-primary-600 text-primary-foreground hover:bg-primary-600 hover:text-primary-foreground"
  end

  def default_class
    "hover:bg-gray-100 hover:text-primary-600"
  end

  def page_path(page_number)
    uri = URI.parse(@path)
    uri.query = @params.merge({ page: page_number }).to_query
    uri.to_s
  end
end
