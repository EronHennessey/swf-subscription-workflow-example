require 'aws'
require './generic_workflow.rb'
require './console_interface.rb'
require './get_subscription_info_activity.rb'
require './subscribe_user_activity.rb'
require './confirm_email_activity.rb'
require './confirm_sms_activity.rb'
require './send_subscription_success_activity.rb'

module SubscriptionWorkflowExample
  # Handles execution of the subscribe workflow.
  #
  class SubscribeWorkflow < GenericWorkflow

    attr_reader :workflow_data

    # Creates a new user subscription workflow.
    #
    # The subscription workflow looks like this:
    #
    #     activities = [ get_subscription_info, subscribe_user, [ confirm_email, confirm_sms, :or ], send_subscription_success ]
    #
    # @param domain
    #   The [Domain](http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SimpleWorkflow/Domain.html) to register the
    #   workflow in.
    #
    # @param [String] task_list
    #   The task list to use for decision tasks.
    #
    # @param [GenericInterface] generic_interface
    #   The generic interface that is used to communicate with the user.
    #
    def initialize(domain_name, generic_interface)

      # Call the GenericWorkflow initialize method. This handles initialization of Amazon SWF and registers the
      # workflow.
      super(domain_name, 'subscribe')

      @workflow_data = {} # a holding place for workflow data.
      @interface = generic_interface

      # add the activities.
      subscription_info_activity = GetSubscriptionInfoActivity.new(self, generic_interface)
      add_activity(subscription_info_activity)
      add_activity(SubscribeUserActivity.new(self, subscription_info_activity.name))
      add_activity([ConfirmEmailActivity.new(self),
        ConfirmSMSActivity.new(self), :or])
      add_activity(SendSubscriptionSuccessActivity.new(self))

      # add some event handlers
      add_event_handler('ActivityTaskCompleted', :handle_activity_completed)
      add_event_handler('ActivityTaskTimedOut', :handle_activity_timed_out)
    end

    # Handle ActivityTaskCompleted events
    def handle_activity_completed(decision_task, event)
      puts "SubscribeWorkflow # handle_activity_completed"

      # if the activity has any data, store it.
      if event.attributes[:result] != nil
        result_data = YAML::load(event.attributes[:result])
        # copy the activity result data into the workflow data
        result_data.keys.each do | key |
          @workflow_data[key] = result_data[key]
        end
      end

      # schedule the next activity (or set of activities). If none remain, then mark the workflow as complete.
      @cur_activity_index += 1
      if @activities.count == @cur_activity_index
        decision_task.complete_workflow_execution
      else
        schedule_cur_activity(decision_task)
      end
    end

    # Handle ActivityTaskTimedOut events
    def handle_activity_timed_out(decision_task, event)
      puts "SubscribeWorkflow # handle_activity_timed_out"
    end
  end
end

