module SubscriptionWorkflowExample
  # A generic workflow class. It includes an activity list and a decider to interact with SWF.
  class GenericWorkflow

    # Creates a new GenericWorkflow.
    #
    # @param [String] domain
    #   The domain that the workflow will run within.
    #
    # @param [String] task_list
    #   The task list that will be used to poll for decision tasks.
    #
    # @param [Array] activity_list
    #   A list of activities to initialize the workflow with.
    #
    #   **Note**: Even if you add activities this way, you can still call {#add_activity} to add new activities until
    #   {#start_workflow} is called.
    #
    def initialize(domain, task_list, activity_list = nil)
      @domain = domain
      @task_list = task_list
      if(activity_list.nil?)
        @activities = []
      else
        @activities = activity_list
      end
      @event_handlers = {}
      @running = false
      @workflow_execution = nil
    end

    # Begins the workflow. Once the workflow has started, it cannot be modified (in other words, you can't
    # {#add_activity add new activities} to it).
    def start_workflow
      @running = true
      @workflow_execution = @workflow.start_execution
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
      if @running
        raise "Can't add an activity while the workflow is running!"
        return false
      end
      # Add the new activity (or group) to the end of the activity list.
      @activities += activity
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
      @event_handlers[event_type.to_sym] = handler
    end

    # Runs the given activity (or set of activities).
    #
    # @param [GenericActivity, Array<GenericActivity>] activity
    #   The activity to run, or an array of activities to run concurrently.
    #
    def run_activity(activity)
      if activity.kind_of?(Array)
         activity.each do | a |
            Thread.new(a.start)
         end
      elsif activity.kind_of?(GenericActivity)
        Thread.new(activity.start)
      end
    end

    # The generic decider. All we're doing here is finding the right callback based on the event, and then calling
    # (`send`ing to) it.
    def poll_for_decision_tasks
      @domain.decision_tasks.poll(@task_list_name) do | decision_task |
        decision_task.new_events.each do | event |
          puts "\nEvent received: #{event.inspect}"
          case event.event_type
          when 'WorkflowExecutionStarted' # Schedule the first activity.
            @cur_activity = 0
            run_activity(@activities[@cur_activity])
          when 'WorkflowExecutionCompleted' # The workflow completed!
            @cur_activity += 1
            run_activity(@activities[@cur_activity])
          else
            # find the handler...
            handler = @event_handlers[event.event_type]
            if handler != nil
              # and call it.
              send(handler, event)
            end
          end
        end
      end
    end
  end
end


