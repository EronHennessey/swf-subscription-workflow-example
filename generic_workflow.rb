require 'aws'
#require 'logger'

# This module contains all of the classes and methods that comprise the Subscription Workflow Example.
#
module SubscriptionWorkflowExample
  # A generic workflow class. It includes an activity list and a decider to interact with Amazon Simple Workflow Service
  # (SWF).
  #
  class GenericWorkflow

    attr_accessor :swf_workflow
    attr_accessor :swf_domain

    # Creates a new GenericWorkflow and registers it, if necessary, with Amazon Simple Workflow (SWF). If you use this
    # as a base class, you should invoke this constructor via `super` in your own class' initialize method.
    #
    # @param [String] domain_name
    #   The domain that the workflow will run within.
    #
    # @param [String] workflow_name
    #   The workflow name to use when registering the workflow with SWF.
    #
    # @param [Hash] workflow_options
    #   The workflow options to use. These are the same options listed in
    #   [WorkflowTypeCollection#register](http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SimpleWorkflow/WorkflowTypeCollection.html#register-instance_method).
    #   If no options are provided, then the following default values will be used:
    #
    #       :default_child_policy                     => :terminate
    #       :default_execution_start_to_close_timeout => 86400 # 1d
    #       :default_task_start_to_close_timeout      => 3600  # 1h
    #       :default_task_list                        => task_list
    #       :description                              => "#{domain} #{workflow_name} workflow"
    #
    # @param [Array] activity_list
    #   A list of activities to initialize the workflow with. If no activities are provided, you can use {#add_activity}
    #   to add them after workflow creation.
    #
    #   **Note**: Even if you add activities this way, you can still call {#add_activity} to add new activities until
    #   {#start} is called.
    #
    def initialize(domain_name, workflow_name, workflow_options = nil, activity_list = nil)
      puts "#{self.class}##{__method__}(#{domain_name}, #{workflow_name})"
      #@logger = Logger.new("#{domain_name}-decision.log")
      #@logger.level = Logger::INFO
      @swf = AWS::SimpleWorkflow.new

      # First, check to see if the domain already exists and is registered.
      @swf.domains.registered.each do | d |
        if(d.name == domain_name)
          @swf_domain = d
        end
      end

      if @swf_domain.nil?
        # Register the domain for just a day. This is merely a test, after all.
        @swf_domain = @swf.domains.create(domain_name, 1, { :description => "#{domain_name} domain" })
      else
        puts "  Domain found: #{@swf_domain.inspect}"
        puts "  Status: #{@swf_domain.status}"
      end

      @name = workflow_name
      @task_list = "#{domain_name}-#{workflow_name}-tasks".downcase

      if(activity_list.nil?)
        @activities = []
      else
        @activities = activity_list
      end

      @swf_workflow = nil

      # Check to see if the workflow already exists.
      @swf_domain.workflow_types.each do | w |
        if w.name == @name
          @swf_workflow = w
        end
      end

      # if workflow options were not passed in, set some defaults.
      if workflow_options.nil?
        # set some defaults.
        workflow_options = {
          :default_child_policy => :terminate,
          :default_execution_start_to_close_timeout => 86400, # 1d
          :default_task_start_to_close_timeout => 3600 } # 1h
      end

      if workflow_options[:description].nil?
        workflow_options[:description] = "#{@swf_domain.name} #{@name} workflow"
      end

      if workflow_options[:default_task_list].nil?
        workflow_options[:default_task_list] = @task_list
      end

      # Register the workflow
      if @swf_workflow == nil
        @swf_workflow = @swf_domain.workflow_types.register(@name, "v3", workflow_options)
      end

      # Some data that will be used later. Setting initial values here.
      @event_handlers = {}
      @success_condition = nil
      @swf_workflow_execution = nil
      @cur_activity_index = 0
    end

    # Begins the workflow. Once the workflow has started, it cannot be modified (in other words, you can't
    # {#add_activity add new activities} to it).
    def start
      puts "#{self.class}##{__method__}"
      @running = true
      @swf_workflow_execution = @swf_workflow.start_execution
      while @swf_workflow_execution.open?
        puts "\n>>> poll_for_decision_tasks! >>>\n"
        poll_for_decision_tasks
        puts "\n<<< poll_for_decision_tasks! <<<n"
        sleep(0.4)
        puts "\n>>> poll_for_activity_tasks! >>>\n"
        poll_for_activity_tasks
        puts "\n<<< poll_for_activity_tasks! <<<n"
        sleep(0.25)
      end
    end

    # Adds a new activity, or list of activities, to the end of the activity queue.
    #
    # If a list is given, the activities in the list will run concurrently. To create sequential activities, use
    # multiple calls of `add`. For example:
    #
    #     myWorkflow.add(activity1)
    #     myWorkflow.add(activity2)
    #     myWorkflow.add([activity3, activity4])
    #     myWorkflow.add(activity5)
    #
    # This will create a workflow that executes *activity1* and *activity2* sequentially, then it runs *activity3* and
    # *activity4* concurrently, and then runs *activity5*.
    #
    # @param [GenericActivity, Array<GenericActivity>] activity
    #   Either a single activity or a list of activities.
    #
    def add_activity(activity)
      puts "#{self.class}##{__method__} (#{activity})"
      if @running
        raise "Can't add an activity while the workflow is running!"
        return false
      end
      # Add the new activity (or group) to the end of the activity list.
      @activities << activity
    end

    # Adds an event handler for the given event. When the event is detected by the workflow, the handler will be called
    # with the event data.
    #
    # @param [String] event_type
    #   The event type to handle. This can be the name of any event returned by a
    #   [DecisionTask](http://docs.aws.amazon.com/amazonswf/latest/apireference/API_DecisionTask.html). You can find a
    #   list of event types in the
    #   [HistoryEvent](http://docs.aws.amazon.com/amazonswf/latest/apireference/API_HistoryEvent.html) documentation.
    #
    # @param [Symbol] handler
    #   A symbol that represents the name of the handler for the event. The handler must take a single parameter, a
    #   **HistoryEvent**, as its input.
    #
    # @note
    #   If you add a handler for an event that was already assigned a handler, the event will be assigned to the new
    #   handler, and the old handler will be forgotten.
    #
    def add_event_handler(event_type, handler)
      puts "#{self.class}##{__method__}"
      @event_handlers[event_type.to_sym] = handler
    end

    # Starts the given activity using an activity task received from SWF.
    #
    # Since the activity task might be one that is being run in parallel with another, this method tries to match the
    # activity name with the activity, or activities, that is currently scheduled.
    #
    # @param [String] activity_task
    #   The activity to run.
    #
    def run_activity(activity_task)
      activity_name = activity_task.activity_type.name
      puts "#{self.class}##{__method__} (#{activity_name})"

      cur_activity = @activities[@cur_activity_index]

      # If cur_activity is an array, check to see which activity on the list should be run.
      if cur_activity.kind_of?(Array)
        puts "  Running activity from array"
        found = false
        cur_activity.each do | a |
          if a.kind_of?(GenericActivity) && (a.name == activity_name)
            a.start(activity_task)
            found = true
          end
        end
        if(found == false)
          puts "  activity #{activity_name} could not be found on the list of activities"
          puts "  currently scheduled:"
          cur_activity.each do | a |
            puts "  *  #{a.name}"
          end
        end
      elsif cur_activity.kind_of?(GenericActivity)
        if (cur_activity.name == activity_name)
          puts "  Running single activity (#{cur_activity.name})"
          cur_activity.start(activity_task)
        else
          puts "  Weird, the passed-in activity #{activity_name} is not the activity"
          puts "  currently scheduled (#{cur_activity.name})!"
        end
      else
        puts "  unknown type: #{cur_activity}"
      end
    end

    # Schedule an activity (or set of activities) using a decision task received from SWF.
    #
    # If the current activity to run is a list, this will schedule a series of activities, until all of the activities
    # on the list have been scheduled.
    #
    # If an array item is a *success condition* (either `:and` or `:or`), then it is used as the success condition for
    # the set: either all of the activities must succeed, or any of the activities can succeed, for the entire group to
    # be considered a success.
    #
    # @param decision_task
    #   The decision task received via {#poll_for_decision_tasks}
    #
    def schedule_cur_activity(decision_task)
      puts "#{self.class}##{__method__} (#{@cur_activity_index})"

      cur_activity = @activities[@cur_activity_index]

      # if this is a list, schedule each activity on the list.
      if cur_activity.kind_of?(Array)
         puts "  In array"
         cur_activity.each do | a |
           if a.kind_of?(GenericActivity)
             puts "  *  Scheduling activity (#{a.name})"
             decision_task.schedule_activity_task(a.swf_activity, { :control => a.name })
           elsif a.kind_of?(Symbol) # :and, :or
             puts "  *  Recording array success condition (#{a.to_s})"
             @success_condition = a
           end
         end
      elsif cur_activity.kind_of?(GenericActivity)
        puts "  Scheduling activity (#{cur_activity.name})"
        decision_task.schedule_activity_task(cur_activity.swf_activity, { :control => cur_activity.name })
      else
        puts "  Unknown type: #{cur_activity}"
      end
    end

    # Poll for any activity tasks. This is called in a loop, along with {#poll_for_decision_tasks}, in {#start}.
    #
    def poll_for_activity_tasks
      puts "#{self.class}##{__method__}"
      if activity_task = @swf_domain.activity_tasks.poll_for_single_task(@task_list)
        puts "  Activity task received: #{activity_task.activity_type.name}"
        run_activity(activity_task)
      end
    end

    # Poll for any decision tasks. This is called in a loop, along with {#poll_for_activity_tasks}, in {#start}.
    #
    # This method is also known as the 'decider', and handles decision events that are initiated by Amazon SWF.
    #
    # Generally, it will pass any decision tasks to the latest event handler assigned for that event. There are some
    # special decision tasks that are *always* handled here, however:
    #
    # * `WorkflowExecutionStarted` - schedules the first activity added to the workflow with {#add_activity} or
    #   {#initialize}.
    #
    # * `WorkflowExecutionCompleted` - completes the workflow execution.
    #
    def poll_for_decision_tasks
      puts "#{self.class}##{__method__}"
      # get a single task
      if decision_task = @swf_domain.decision_tasks.poll_for_single_task(@task_list)
        decision_task.new_events.each do | event |
          puts "  Decision event received: #{event.inspect}"
          case event.event_type
          when 'WorkflowExecutionStarted' # Schedule the first activity.
            schedule_cur_activity(decision_task)
          when 'WorkflowExecutionCompleted' # The workflow completed!
            puts "  Workflow execution complete!"
          else
            # find the handler...
            handler = @event_handlers[event.event_type.to_sym]
            if handler != nil
              # and call it.
              send(handler, decision_task, event)
            end
          end
        end
        decision_task.complete!
      end
    end
  end
end

