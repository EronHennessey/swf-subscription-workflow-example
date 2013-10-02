require_relative 'utils.rb'

# Base for activities in the SWF+SNS sample.
class BasicActivity

  attr_accessor :activity_type
  attr_accessor :name
  attr_accessor :results

  # Initializes a BasicActivity.
  #
  # @param [AWS::SimpleWorkflow::Domain] domain
  #   The domain that this activity belongs to.
  #
  # @param [String] task_list
  #   The name of the task list used to receive activity tasks.
  #
  # @param [String] name
  #   The activity's name, which will be used to identify the activity to SWF
  #   and to other parts of the workflow.
  #
  # @param [AWS::SimpleWorkflow::ActivityOptions] activity_options
  #   The options for the ActivityType that will be registered when the
  #   BasicActivity is initialized.
  #
  def initialize(domain, task_list, name = 'basic_activity', activity_options = nil)
    @domain = domain
    @task_list = task_list
    @activity_type = nil
    @results = nil
    @name = "#{name}-#{task_list}"

    # If no options were specified, use some reasonable defaults.
    if activity_options.nil?
      activity_options = {
        :default_task_list => @task_list,
        # All timeouts are in seconds.
        :default_task_heartbeat_timeout => 900,
        :default_task_schedule_to_start_timeout => 120,
        :default_task_schedule_to_close_timeout => 3800,
        :default_task_start_to_close_timeout => 3600 }
    else
      activity_options[:default_task_list] = @task_list
    end

    # Check to see if this activity type already exists.
    @domain.activity_types.each do | a |
      if a.name == @name
        if(@activity_type.nil?)
          @activity_type = a
        else
        end
      end
    end

    # a default value...
    activity_version = '1'

    if @activity_type
      # the activity was found. Check to see if the options are the same.
      options_differ = false
      activity_options.keys.each do | option_type |
        if @activity_type.send(option_type) != activity_options[option_type]
          options_differ = true
        end
      end

      # if the options differ, we need to change the version.
      if options_differ
        activity_version = @activity_type.version
        begin
          # hopefully, it's just a number...
          n = Integer (activity_version)
          activity_version = String(n.next)
        rescue
          # ...if not, attempt to split the numeric part of the string from the
          # rest of it
          (activity_version, n) = activity_version.partition("\d+")
          n = n.to_i
          activity_version << String(n.next)
        end
        # options differ, so we'll register the activity type again
        @activity_type = nil
      end
    end

    if @activity_type.nil?
      @activity_type = domain.activity_types.create(@name, activity_version, activity_options)
    end
  end

  # Performs tha activity.
  #
  # Usually called by the activity task poller, this method should always set a
  # value for `@results`, which must be a string. The contents of `@results`
  # will be submitted to the next activity in the sequence by SWF.
  #
  # The base class version of this is *meant* to be overridden, and just copies
  # the input to the results.
  #
  # @param [String] input
  #   The input to the activity, as passed in through the activity task.
  #
  # @return [Boolean]
  #   `true` if the activity completed successfully, or `false` if it failed.
  #
  def do_activity(input)
    @results = input
    return true
  end

  # Handles an activity task returned by
  # {AWS::SimpleWorkflow::Domain.activity_tasks#poll}
  #
  # @param [AWS::SimpleWorkflow::ActivityTask] task
  #   The that was received by the activity task poller.
  #
  def handle_activity_task(task)
    # default behavior is to just do the activity and return completion.
    if do_activity(task.input)
      task.complete!({ :result => @results })
    else
      task.fail!({ :reason => @results[:reason], :details => @results[:details]})
    end
  end

  #
  # Polls for activities until the activity is marked complete.
  #
  def poll_for_activities
    @domain.activity_tasks.poll(@task_list) do | task |
      if task.activity_type.name == @name
        return handle_activity_task(task)
      end
    end
  end

end

