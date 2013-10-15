require 'yaml'
require_relative 'basic_activity.rb'

#
# **SubscribeTopicActivity** sends an SMS / email message to the user, asking for
# confirmation.  When this action has been taken, the activity is complete.
#
class SubscribeTopicActivity < BasicActivity

  def initialize
    super('subscribe_topic_activity', 'v1')
  end

  # Create an SNS topic and return the ARN
  def create_topic(sns_client)
    topic_arn = sns_client.create_topic(:name => 'SWF_Sample_Topic')

    if topic_arn != nil
      # For an SMS notification, setting `DisplayName` is *required*. Note that
      # only the *first 10 characters* of the DisplayName will be shown on the
      # SMS message sent to the user, so choose your DisplayName wisely!
      sns_client.set_topic_attributes({
        :topic_arn => topic_arn,
        :attribute_name => 'DisplayName',
        :attribute_value => 'SWFSample' })
    else
      @results = {
        :reason => "Couldn't create SNS topic", :detail => "" }.to_yaml
      return nil
    end

    return topic_arn
  end

  # Attempt to subscribe the user to an SNS Topic.
  def do_activity(task)
    puts("#{@name}: #{__method__} #{task.inspect}")

    activity_data = {
      :topic_arn => nil,
      :email => { :endpoint => nil, :subscription_arn => nil },
      :sms => { :endpoint => nil, :subscription_arn => nil },
    }

    if task.input != nil
      input_data = YAML.load(task.input)
      email = input_data[:email]
      sms = input_data[:sms]
    else
      @results = { :reason => "Didn't receive any input!", :detail => "" }.to_yaml
      puts("  #{@results.inspect}")
      return false
    end

    # Create an SNS client. This is used to interact with the service. Set the
    # region to $SMS_REGION, which is a region that supports SMS notifications
    # (defined in the file `swf_sns_utils.rb`).
    sns_client = AWS::SNS::Client.new(
      :config => AWS.config.with(:region => $SMS_REGION))

    # Create the topic and get the ARN
    activity_data[:topic_arn] = create_topic(sns_client)

    if activity_data[:topic_arn].nil?
      return false
    end

    # Subscribe the user to the topic, using either or both endpoints.
    [:email, :sms].each do | protocol |
      endpoint = activity_data[protocol][:endpoint]
      # don't try to subscribe an empty endpoint
      if (endpoint != nil && endpoint != "")
        response = sns_client.subscribe({
          :topic_arn => topic_arn,
          :protocol => protocol.to_s,
          :endpoint => endpoint})
        activity_data[protocol][:subscription_arn] = response[:subscription_arn]
      end
    end

    # if at least one subscription arn is set, consider this a success.
    if (activity_data[:email][:subscription_arn] != nil) or (activity_data[:sms][:subscription_arn] != nil)
      @results = activity_data.to_yaml
    else
      @results = { :reason => "Couldn't subscribe to SNS topic", :detail => "" }.to_yaml
      puts("  #{@results.inspect}")
      return false
    end
    return true
  end
end
