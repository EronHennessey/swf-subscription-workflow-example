module SubscriptionWorkflowExample
  # A generic activity class.
  class GenericActivity

    # Creates a new GenericActivity
    #
    # @param workflow
    #   An SWF [WorkflowType](http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SimpleWorkflow/WorkflowType.html) object
    #   that has been registered on a domain.
    #
    # @param [String] activity_name
    #   The name of the activity.
    #
    # @param [Hash] activity_options
    #   The activity options to use. These are the same options listed in
    #   [ActivityTypeCollection#register](http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SimpleWorkflow/ActivityTypeCollection.html#register-instance_method).
    #   If no options are provided, then the following default values will be used:
    #
    #       :default_task_list                      => workflow.default_task_list
    #       :default_heartbeat_timeout              => :none
    #       :default_task_schedule_to_start_timeout => 120
    #       :default_task_start_to_close_timeout    => 3600
    #       :default_task_schedule_to_close_timeout => 3720
    #
    def initialize(workflow, activity_name, activity_options = nil)
      @swf_workflow = workflow
      @name = activity_name

      if activity_options.nil?
        # set some defaults.
        activity_options = {
          :default_task_list => @swf_workflow.default_task_list,
          :default_heartbeat_timeout => :none,
          :default_task_schedule_to_start_timeout => 120,
          :default_task_start_to_close_timeout => 3600,
          :default_task_schedule_to_close_timeout => 3720
          }
      end

      if activity_options[:description].nil?
        activity_options[:description] = "#{@swf_workflow.name} #{@name} activity"
      end

      @swf_workflow.domain.activity_types.create(@name, '1', activity_options)
    end

    # Sets the thread that is running {#start} on this activity.
    #
    # @param thread
    #   The thread that will run this activity.
    #
    def set_thread(thread)
      @thread = thread
    end

    # Starts the activity.
    # @todo override this in your derived class, then call it to start the activity.
    def start
    end
  end
end

