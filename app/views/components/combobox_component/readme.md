````
      <%= render ComboboxComponent::Bundler.new(
        form: form,
        collection: dummy_tasks,
        method: :task_id,
        value_method: :id,
        text_method: :name,
        mode: :multiple,
        placeholder: "Add Task",
        search_placeholder: "Search a Task",
        selected: {
          title: "Tasks",
          items: Task.all,
          method: "project[assigned_tasks_attributes][]"
        },
        can_add: true,
        size: :fill
      ) %>