#
# **SendResultActivity** sends the result of the activity to the screen, and, if
# the user successfully registered using SNS, to the user using the SNS contact
# information collected.
#
require 'yaml'
require_relative 'basic_activity.rb'

class SendResultActivity < BasicActivity

  def initialize
    super('send_result_activity', 'v1')
  end

  # confirm the SNS topic subscription
  def do_activity(task)
    puts "#{__method__} #{task.inspect}"
    if task.input.nil?
      @results = { :reason => "Didn't receive any input!", :detail => "" }
      return false
    end

    input = YAML.load(task.input)

    # get the topic, so we publish a message to it.
    topic = AWS::SNS::Topic.new(input[:topic_arn])

    if topic.nil?
      @results = {
        :reason => "Couldn't get SWF topic",
        :detail => "Topic ARN: #{topic.arn}" }
      return false
    end

    @results = "Thanks, you've successfully confirmed registration, and your workflow is complete!"

    # send the message via SNS, and also print it on the screen.
    topic.publish(@results)
    puts(@results)

    return true
  end
end

