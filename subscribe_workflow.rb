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
    def initialize(domain, task_list, generic_interface)
      super(domain, 'subscribe', task_list)

      # add the activities.
      add_activity(GetSubscriptionInfoActivity.new(domain, @swf_workflow, generic_interface))
      add_activity(SubscribeUserActivity.new(domain, @swf_workflow))
      add_activity([ConfirmEmailActivity.new(domain, @swf_workflow),
        ConfirmSMSActivity.new(domain, @swf_workflow), :or])
      add_activity(SendSubscriptionSuccessActivity.new(domain, @swf_workflow))

      # add some event handlers
    end
  end
end

