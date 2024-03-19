```haml
= render Dialog::Base.new(title: "Some sort of dialog", subtitle: "Hello") do |d|
  - d.with_show_button(label: "Show Dialog")
  - d.with_body do
    %p Some content
  - d.footer do
    = button_tag "cancel"
    = button_tag "submit"

= form_with model: User.last do |form|
  = render Dialog::Base.new(title: "Edit Thing", subtitle: "Please give new name to thing") do |d|
    - d.with_show_button(label: "Edit this thing")
    - d.with_body do
      = form.label :name
      = form.text_field :name
    - d.footer do
      = button_tag "cancel"
      = form.submit

= render Dialog::Base.new(title: "Image preview") do |d|
  - d.with_show_button(label: "Open image preview")
  - d.with_body do
    = image_tag(@some_image)
```