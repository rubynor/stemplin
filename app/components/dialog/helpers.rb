module Dialog
  module Helpers
    def stimulus_controller
      @stimulus_controller ||= "custom-dialog"
    end

    def call_to_action_class_names
      "rounded-md bg-indigo-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
    end
  end
end
