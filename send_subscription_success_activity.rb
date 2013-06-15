require 'aws'
require './generic_workflow.rb'
require './sns_helper.rb'

module SubscriptionWorkflowExample
  # An activity that sends a success notification to the user, using either the email address or phone number that was
  # confirmed by the confirm-user-email or confirm-user-phone activities.
  class SendSubscriptionSuccessActivity < GenericActivity

    # Creates the send-success activity.
    #
    # @param (see GetSubscriptionInfoActivity)
    #
    def initialize(domain, workflow, interface)
      super(domain, workflow)
      @interface = interface
      @domain.activity_types.create('send-success', '1',
        :default_task_list => @workflow.default_task_list,
        :default_heartbeat_timeout => :none,
        :default_task_schedule_to_start_timeout => 60,
        :default_task_schedule_to_close_timeout => 3660,
        :default_task_start_to_close_timeout => 3600,
        :description => "#{@domain.name} send success activity")
    end

    # Starts an execution of the send-success activity.
    #
    def start
    end
  end
end
