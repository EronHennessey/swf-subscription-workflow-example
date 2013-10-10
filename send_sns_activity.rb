#
# **SendSNSActivity** sends an SMS / email message to the user, asking for
# confirmation.  When this action has been taken, the activity is complete.
#
require 'yaml'
require_relative 'basic_activity.rb'

class SendSNSActivity < BasicActivity

  def initialize
    super('send_sns_activity', 'v1')

    # Create an SNS client. This is used to interact with the service. Set the
    # region to $SMS_REGION, which is a region that supports SMS notifications
    # (defined in the file `swf_sns_utils.rb`).
    @sns_client = AWS::SNS::Client.new(
      :config => AWS.config.with(:region => $SMS_REGION))

    @activity_data = {
      :topic => {
        :name => @name,
        :display_name => 'snsactivity', :arn => nil },
      :email => { :address => nil, :arn => nil },
      :sms => { :address => nil, :arn => nil } }
  end

  # Get some data to use to subscribe to the topic.
  def do_activity(task)
    puts("#{@name}: #{__method__} #{task.inspect}")
    if task.input.nil?
      @results = { :reason => "Didn't receive any input!", :detail => "" }.to_yaml
      puts("  #{@results.inspect}")
      return false
    else
      input_data = YAML.load(task.input)
      @activity_data[:email][:address] = input_data[:email]
      @activity_data[:sms][:address] = input_data[:sms]
    end

    if create_topic
      if subscribe_topic
        # we only need to send the topic data to the next stage.
        @results = @activity_data[:topic].to_yaml
      else
        @results = { :reason => "Couldn't subscribe to SNS topic", :detail => "" }.to_yaml
        puts("  #{@results.inspect}")
        return false
      end
    else
      @results = { :reason => "Couldn't create SNS topic", :detail => "" }.to_yaml
      puts("  #{@results.inspect}")
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
    puts("#{@name}: #{__method__}")
    # create a new SNS topic and get the Amazon Resource Name (ARN).
    response = @sns_client.create_topic(:name => @activity_data[:topic][:name])

    @activity_data[:topic][:arn] = response[:topic_arn]

    # For an SMS notification, setting `DisplayName` is *required*. Note that
    # only the *first 10 characters* of the DisplayName will be shown on the SMS
    # message sent to the user, so choose your DisplayName wisely!
    @sns_client.set_topic_attributes({
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
    puts("#{@name}: #{__method__}")
    [:email, :sms].each do | x |
      address = @activity_data[x][:address]
      if (address != nil && address != "")
        response = @sns_client.subscribe({
          :topic_arn => @activity_data[:topic][:arn],
          :protocol => x.to_s,
          :endpoint => address})
        @activity_data[x][:arn] = response[:subscription_arn]
      else
        @activity_data[x][:arn] = nil
      end
    end
    return true
  end
end
