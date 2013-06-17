require 'aws'

module SubscriptionWorkflowExample
  # A generic activity class.
  class GenericActivity

    # The name of the GenericActivity (also the name registered with SWF)
    attr_reader :name
    attr_accessor :swf_activity

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

      if !(workflow.kind_of?(GenericWorkflow))
        raise "You must initialize a GenericActivity with a GenericWorkflow"
      end

      @workflow = workflow
      @name = activity_name
      swf_workflow = @workflow.swf_workflow

      if activity_options.nil?
        # set some defaults.
        activity_options = {
          :default_task_heartbeat_timeout => :none,
          :default_task_schedule_to_start_timeout => 120, # 2m
          :default_task_start_to_close_timeout => 3600, # 1h
          :default_task_schedule_to_close_timeout => 3720 }
      end

      # make sure that we have a default task list set.
      if activity_options[:default_task_list].nil?
        activity_options[:default_task_list] = swf_workflow.default_task_list
      end

      if activity_options[:description].nil?
        activity_options[:description] = "#{swf_workflow.name} #{@name} activity"
      end

      # check to see if this activity type already exists. If it doesn't, create it.
      swf_workflow.domain.activity_types.each do | a |
        if a.name == @name
          @swf_activity = a
          break
        end
      end

      if @swf_activity.nil?
        @swf_activity = swf_workflow.domain.activity_types.create(@name, '1', activity_options)
      end
    end

    # Starts the activity. This is called by {GenericWorkflow#poll_for_activity_tasks}.
    #
    # @param activity_task
    #   The SWF activity task requesting that the activity is run.
    #
    def start(activity_task)
      @swf_activity_task = activity_task
      @thread = Thread.new { run }
    end

    # Runs the activity. This is called by {#start} to run the activity, and must be overridden in any derived class.
    #
    # @todo override this in your derived class. It will be called to run the activity.
    #
    def run
      raise "GenericActivity#run must be overridden!"
    end
  end
end

