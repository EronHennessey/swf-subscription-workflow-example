#
# **SendSNSActivity** sends an SMS / email message to the user, asking for
# confirmation.  When this action has been taken, the activity is complete.
#
require 'yaml'
require_relative 'basic_activity.rb'

class SendSNSActivity < BasicActivity

  def initialize(domain, task_list)
    puts "#{self.class}##{__method__}"
    super(domain, task_list, 'send_sns_activity')

    # Create an SNS client. This is used to interact with the service. Set the
    # region to $SMS_REGION, which is a region that supports SMS notifications
    # (defined in the file `swf_sns_utils.rb`).
    @sns_client = AWS::SNS::Client.new(
      :config => AWS.config.with(:region => $SMS_REGION))

    @activity_data = {
      :topic => {
        :name => 'send-sns-activity-topic',
        :display_name => 'snsactivity', :arn => nil },
      :email => { :address => nil, :arn => nil },
      :sms => { :address => nil, :arn => nil } }
  end

  # Get some data to use to subscribe to the topic.
  def do_activity(input)
    puts "#{self.class}##{__method__}"

    if input.nil?
      @results = { :reason => "Didn't receive any input!", :detail => "" }
      return false
    else
      input_data = YAML.load(input)
      @activity_data[:email][:address] = input_data[:email]
      @activity_data[:sms][:address] = input_data[:sms]
    end

    if create_topic
      if subscribe_topic
        @results = @activity_data.to_yaml
      else
        @results = { :reason => "Couldn't subscribe to SNS topic", :detail => "" }
        return false
      end
    else
      @results = { :reason => "Couldn't create SNS topic", :detail => "" }
      return false
    end
    return true
  end

  # Create the SNS topic
  #
  # @return [String]
  #   The SNS topic Amazon Resource Name (ARN)
  #
  def create_topic
    puts "#{self.class}##{__method__}"
    # create a new SNS topic and get the Amazon Resource Name (ARN).
    response = @sns_client.create_topic(:name => @activity_data[:topic][:name])
    @activity_data[:topic][:arn] = response[:topic_arn]

    # For an SMS notification, setting `DisplayName` is *required*. Note that
    # only the *first 10 characters* of the DisplayName will be shown on the SMS
    # message sent to the user, so choose your DisplayName wisely!
    response = @sns_client.set_topic_attributes({
      :topic_arn => @activity_data[:topic][:arn],
      :attribute_name => "DisplayName",
      :attribute_value => @activity_data[:topic][:display_name] })
    return true
  end

  # Subscribe to the SNS topic
  #
  # @param [String] user_email
  #   The user's email address.
  #
  # @param [String] user_phone
  #   The user's phone number. This phone number must be able to accept SMS
  #   messages.
  #
  def subscribe_topic
    puts "#{self.class}##{__method__}"
    [:email, :sms].each do | x |
      if @activity_data[x][:address] != nil
        response = @sns_client.subscribe({
          :topic_arn => @activity_data[:topic][:arn],
          :protocol => x.to_s,
          :endpoint => @activity_data[x][:address]})
        @activity_data[x][:arn] = response[:subscription_arn]
      end
    end
    return true
  end
end
