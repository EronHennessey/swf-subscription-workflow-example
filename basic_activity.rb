require_relative 'utils.rb'

# Base for activities in the SWF+SNS sample.
class BasicActivity

  attr_accessor :activity_type
  attr_accessor :name
  attr_accessor :results

  # Initializes a BasicActivity.
  #
  # @param [String] name
  #   The activity's name, which will be used to identify the activity to SWF
  #   and to other parts of the workflow.
  #
  # @param [String] version
  #   The version string for the activity.
  #
  # @param [AWS::SimpleWorkflow::ActivityOptions] options
  #   The options for the ActivityType that will be registered when the
  #   BasicActivity is initialized.
  #
  def initialize(name = 'basic_activity', version = 'v1', options = nil)

    @activity_type = nil
    @name = name
    @results = nil

    # If no options were specified, use some reasonable defaults.
    if options.nil?
      options = {
        # All timeouts are in seconds.
        :default_task_heartbeat_timeout => 900,
        :default_task_schedule_to_start_timeout => 120,
        :default_task_schedule_to_close_timeout => 3800,
        :default_task_start_to_close_timeout => 3600 }
    end

    # get the domain to use for activity tasks.
    @domain = init_domain

    # Check to see if this activity type already exists.
    @domain.activity_types.each do | a |
      if (a.name == @name) && (a.version == version)
        # Check to see if the options are the same.
        matches = true
        options.keys.each do | option_type |
          if a.send(option_type) != options[option_type]
            matches = false
          end
        end

        if matches
          @activity_type = a
        end
      end
    end

    if @activity_type.nil?
      @activity_type = @domain.activity_types.create(@name, version, options)
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
  def do_activity(task)
    puts "#{__method__}"
    @results = task.input # may be nil
    return true
  end

  # Handles an activity task returned by
  # {AWS::SimpleWorkflow::Domain.activity_tasks#poll}, and signals to SWF that
  # the task either completed or failed, depending on the value of
  # {do_activity}.
  #
  # @param [AWS::SimpleWorkflow::ActivityTask] task
  #   The that was received by the activity task poller.
  #

end

