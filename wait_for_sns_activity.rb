#
# **WaitForSNSActivity** waits for the user to confirm the SNS subscription.
# When this action has been taken, the activity is complete. It might also time
# out...
#
require 'yaml'
require_relative 'basic_activity.rb'

class WaitForSNSActivity < BasicActivity

  def initialize
    super('wait_for_sns_activity', 'v1')
  end

  # confirm the SNS topic subscription
  def do_activity(task)
    if task.input.nil?
      @results = { :reason => "Didn't receive any input!", :detail => "" }.to_yaml
      return false
    end

    input = YAML.load(task.input)

    # get the topic, so we can see if the user confirmed the subscription.
    topic = AWS::SNS::Topic.new(input[:arn])

    if topic.nil?
      @results = {
        :reason => "Couldn't get SWF topic",
        :detail => "Topic ARN: #{topic.arn}" }.to_yaml
      return false
    end

    # loop until we get some indication that a subscription was confirmed.
    while ((topic.num_subscriptions_confirmed < 1) && (topic.num_subscriptions_pending > 0))
      # check the subscriptions
      topic.subscriptions.each do | sub |
        if sub.arn != 'PendingConfirmation'
          puts "Topic subscription confirmed for (#{sub.protocol}: #{sub.endpoint})"
        else
          puts "Topic subscription pending for (#{sub.protocol}: #{sub.endpoint})"
        end

      end
      # send a heartbeat notification to SWF to keep the activity alive...
      task.record_heartbeat!(
        { :details => "#{topic.num_subscriptions_confirmed} confirmed, #{topic.num_subscriptions_pending} pending" })
      # sleep a bit.
      sleep(4.0)
    end

    # if nothing is confirmed, assume that the user did not authenticate.
    if (topic.num_subscriptions_confirmed < 1)
      @results = {
        :reason => "No subscriptions could be confirmed",
        :detail => "#{topic.num_subscriptions_confirmed} confirmed, #{topic.num_subscriptions_pending} pending" }.to_yaml
      return false
    end

    # If we're here, the user confirmed with either an email address or SMS
    # address. We're good to complete the activity.
    @results = input.to_yaml
    return true
  end
end
