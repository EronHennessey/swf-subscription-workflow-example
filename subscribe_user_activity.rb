require 'aws'
require './generic_activity.rb'
require './sns_helper.rb'

module SubscriptionWorkflowExample
  # An activity that subscribes the user to an SNS topic
  class SubscribeUserActivity < GenericActivity

    # The subscription data for the SNS topic. This is a hash with the following keys:
    #
    # * :topic_arn - the SNS topic's Amazon Resource Name (ARN)
    # * :subscription_arns - ARNs for each of the user_data elements.
    #
    attr_reader :subscription_data

    # Creates the subscribe-user activity.
    #
    # @param [GenericWorkflow] workflow
    #   The generic workflow that this activity is running in
    #
    # @param [String] user_data_key
    #   The {SubscribeWorkflow#workflow_data} key that contains the user's email address and phone number.
    #
    def initialize(workflow, user_data_key)
      puts "#{self.class}##{__method__} (#{workflow}, #{user_data_key})"
      @user_data_key = user_data_key

      # this task interacts with SWF and SNS, so while there may be some delay in subscribing the user, it won't take
      # that long. We can reasonably time out in 2 minutes.
      activity_options = {
        :default_task_heartbeat_timeout => :none,
        :default_task_schedule_to_start_timeout => 360, # 1m
        :default_task_start_to_close_timeout => 360,    # 1m
        :default_task_schedule_to_close_timeout => 720 }

      super(workflow, 'subscribe-user-sns', activity_options)
    end

    # Starts an execution of the subscribe-user activity.
    #
    def run
      puts "#{self.class}##{__method__} (#{@name}, #{@workflow.swf_workflow.domain.name})"

      @sns_helper = SNSHelper.new(@name, @workflow.swf_workflow.domain.name)

      puts "creating topic..."

      @subscription_data[:topic_arn] = @sns_helper.create_topic

      puts "#{@subscription_data}"

      puts "subscribing to topic #{@subscription_data[:topic_arn]} #{@user_data_key.inspect}"

      user_data = @workflow.workflow_data[@user_data_key]
      @subscription_data[:subscription_arns] = @sns_helper.subscribe_topic(user_data[:email], user_data[:sms])

      puts 'success or fail?...'
      if @subscription_data[:topic_arn].nil? || @subscription_data[:subscription_arns].nil?
        @swf_activity_task.fail!(:reason => "#{@name} failed")
      else
        @swf_activity_task.complete!( :result => YAML.dump({ @name => @subscription_data }) )
      end
    end
  end
end

