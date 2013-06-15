require 'aws'
require './generic_activity.rb'
require './generic_interface.rb'

module SubscriptionWorkflowExample
  # An activity that collects subscription information from the user.
  class GetSubscriptionInfoActivity < GenericActivity
    # Creates the get-subscription-info activity.
    #
    # @param domain
    #   The SWF domain that the workflow is running in.
    #
    # @param [GenericWorkflow] workflow
    #   The generic workflow that this activity is running in
    #
    # @param [GenericInterface] interface
    #   The generic interface that is used to communicate with the user.
    #
    def initialize(domain, workflow, interface)
      super(domain, workflow)
      # TODO: if interface.respond_to?(:get_subscription_data)
      @interface = interface
      # Register the activity.
      @domain.activity_types.create('get-subscription-info', '1',
        :default_task_list => @workflow.default_task_list,
        :default_heartbeat_timeout => :none,
        :default_task_schedule_to_start_timeout => 60,
        :default_task_schedule_to_close_timeout => 3660,
        :default_task_start_to_close_timeout => 3600,
        :description => "#{@domain.name} get subscription info activity")
    end

    # Starts an execution of the get-subscription-info activity.
    #
    def start
      # this will block until the user has entered the information.
      subscription_data = @interface.get_subscription_data
    end
  end
end
