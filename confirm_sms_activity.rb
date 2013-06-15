require 'aws'
require './generic_workflow.rb'
require './sns_helper.rb'

module SubscriptionWorkflowExample
  # An activity that waits for confirmation of the user's SMS phone number.
  class ConfirmSMSActivity < GenericActivity

    # Creates the confirm-user-phone activity.
    #
    # @param (see GetSubscriptionInfoActivity)
    #
    def initialize(domain, workflow, interface)
      super(domain, workflow)
      @interface = interface
      @domain.activity_types.create('confirm-user-phone', '1',
        :default_task_list => @workflow.default_task_list,
        :default_heartbeat_timeout => :none,
        :default_task_schedule_to_start_timeout => 60,
        :default_task_schedule_to_close_timeout => 3660,
        :default_task_start_to_close_timeout => 3600,
        :description => "#{@domain.name} confirm phone activity")
    end

    # Starts an execution of the confirm-user-phone activity.
    #
    def start
    end
  end
end
