require 'aws'
require 'yaml'
require './generic_activity.rb'
require './generic_interface.rb'

module SubscriptionWorkflowExample
  # An activity that collects subscription information from the user.
  class GetSubscriptionInfoActivity < GenericActivity

    # Creates the get-subscription-info activity.
    #
    # @param [GenericWorkflow] workflow
    #   The generic workflow that this activity is running in
    #
    # @param [GenericInterface] interface
    #   The generic interface that is used to communicate with the user.
    #
    def initialize(workflow, interface)
      puts "#{self.class}##{__method__}"
      @interface = interface

      # this is a human task, and we expect the person to type in an e-mail address and/or phone number. If the person
      # doesn't type these in within a 15 minute period, assume that they left the terminal and time out.
      activity_options = {
        :default_task_heartbeat_timeout => :none,
        :default_task_schedule_to_start_timeout => 60, # 60s
        :default_task_start_to_close_timeout => 900, # 15m
        :default_task_schedule_to_close_timeout => 960 }

      super(workflow, 'get-subscription-info', activity_options)
    end

    # Starts an execution of the get-subscription-info activity.
    #
    def run
      puts "#{self.class}##{__method__}"

      # this will block until the user has entered the information.
      subscriber_data = @interface.get_subscriber_data
      if subscriber_data[:email].nil? && subscriber_data[:sms].nil?
        @swf_activity_task.fail!(:reason => "#{@name} failed")
      else
        @swf_activity_task.complete!( :result => YAML.dump({ @name => subscriber_data }) )
      end
    end
  end
end
