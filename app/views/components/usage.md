# Usage
For component props refer to PhlexUI components attributes, this is just to abstract direct Phlex::UI components usage across the codebase where we think we could have duplicate efforts.

## 1. ButtonComponent

### Simple button
`= render ButtonComponent.new {}`

### button_to
```      
<%= render ButtonComponent.new(path: new_modal_time_regs_path, method: :post, class: "flex flex-col h-16 w-16") do %>
    <i class="uc-icon text-6xl text-white">&#xead5;</i>
    <p class="mt-4 text-lg text-gray-600">
    Track time
    </p>
<% end %>
```


## 2. CardComponent

`= render CardComponent.new {}`

## 3. Snackbar component or flash messages


### Example 1
`flash[:notice|:alert|:error|:success] = "Lorem ipsum dolor sit amet"`

### Example 2

```
          flash[:notice] = {
            title: "Lorem ipsum", # Required in case you pass a Hash to flash
            body: "", # Optional
            timeout: 100, # Optional, default is 6 seconds
            countdown: true, # Optional, will display a countdown bar
            action: { # Optional, this is in case you'd like to attach an action to the snackbar
              url: root_path, # Required in case you pass a Hash to action
              method: :get, # Required in case you pass a Hash to action
              name: "Get started", # Required in case you pass a Hash to action
              data_attributes: {turbo: false} # Optional, only if you need to pass data attributes
            }
          }
```

### Example 3 
`        render turbo_stream: turbo_flash(type: ":notice|:alert|:error|:success", data: "Message here")`


`        render turbo_stream: turbo_flash(type: ":notice|:alert|:error|:success",data: {title: "Message here", body: "Body here", timeout: 6, countdown: true, action: {url: root_path, method: :get, name: "Get started", data_attributes: {turbo: false}})`
