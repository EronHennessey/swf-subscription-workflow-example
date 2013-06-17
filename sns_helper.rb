require 'aws'

module SubscriptionWorkflowExample

  # Creates an Amazon Simple Notification Service (SNS) topic and provides operations that can be performed on it, such
  # as subscribing a user to the topic and deleting it.
  class SNSHelper

    # SMS messaging is currently available *only* in the `us-east-1` region.
    @@SMS_REGION = 'us-east-1'

    # Creates a new instance of SNSHelper and creates a new SNS client object.
    #
    # @param [String] topic_name
    #   The name of the SNS topic to create. This is the programmatic name, and not seen by the end user.
    #
    # @param [String] display_name
    #   The display name of the topic. A few notes about the display name:
    #
    #   * Setting the display name is *required* for SMS notifications.
    #
    #   * For an SMS notification, only the first 10 characters will be seen by the user, and will be used to respond
    #     back (the user will respond via SMS: "YES <DISPLAYNAME>").
    #
    #   * For an email notification, the display name will be used as the value of the "From" field in the email header.
    #
    # @param [String] aws_region
    #   The AWS region to use.
    #
    def initialize(topic_name, display_name, aws_region = @@SMS_REGION)
      # Data for an instance. An instance handles one subscriber's data at a time.
      @aws_region = aws_region
      @topic_data = { :topic_name => topic_name, :display_name => display_name, :arn => nil }
      @subscriber_data = { :email => nil, :sms => nil }
      @subscription_arns = { :email => nil, :sms => nil }

      # Create an SNS client. This is used to interact with the service. Set the region to use to be whatever the user
      # passed in, or @@SMS_REGION, which is a region that supports SMS notifications.
      @sns_client = AWS::SNS::Client.new(:config => AWS.config.with(:region => aws_region))
    end # initialize

    # Create the SNS topic
    #
    # @return [String]
    #   The SNS topic Amazon Resource Name (ARN)
    #
    def create_topic
      puts "SNSHelper # create_topic ( #{@topic_data[:topic_name]} )"
      # create a new SNS topic and get the Amazon Resource Name (ARN).
      response = @sns_client.create_topic(:name => @topic_data[:topic_name])
      @topic_data[:arn] = response[:topic_arn]

      # For an SMS notification, setting `DisplayName` is *required*. Note that only the *first 10 characters* of the
      # DisplayName will be shown on the SMS message sent to the user, so choose your DisplayName wisely!
      response = @sns_client.set_topic_attributes({
        :topic_arn => @topic_data[:arn],
        :attribute_name => "DisplayName",
        :attribute_value => @topic_data[:display_name] })

      puts "SNSHelper # create_topic (out)"
      # return the ARN
      return @topic_data[:arn]
    end # create_topic

    # Subscribe to the SNS topic
    #
    # @param [String] user_email
    #   The user's email address.
    #
    # @param [String] user_phone
    #   The user's phone number. This phone number must be able to accept SMS messages.
    #
    def subscribe_topic(user_email, user_phone)
      puts "SNSHelper # subscribe_topic ( #{user_email}, #{user_phone} )"

      @subscriber_data[:email] = user_email
      @subscriber_data[:sms] = user_phone

      @subscriber_data.keys.each do | x |
        if @subscriber_data[x] != nil
          response = @sns_client.subscribe({
            :topic_arn => @topic_data[:arn],
            :protocol => x.to_s,
            :endpoint => @subscriber_data[x.to_sym]})
          @subscription_arns[x.to_sym] = response[:subscription_arn]
        end
      end
      return @subscription_arns
    end # subscribe_topic

    # Gets the subscription status of the user to the topic.
    #
    # @param [Symbol] type
    #   The subscription type (`:email` or `:sms`) to query.
    #
    # @return [String]
    #   The subscription status as returned by AWS SNS. This will either be the ARN (if subscription was successful) or
    #   the string "PendingConfirmation" if the subscription is still pending confirmation.
    #
    #   If no subscription request is active for the *type* provided, then `nil` will be returned.
    #
    def get_subscription_status(type)
      if(@topic_data[:arn] == nil)
        return 'Error: Topic not created.'
      end

      if !(type == :email || type == :sms)
        return "Error: invalid subscription method: #{type}"
      end

      response = @sns_client.list_subscriptions_by_topic(:topic_arn => @topic_data[:arn])
      subscriptions = response.data[:subscriptions]

      subscriptions.each do | subscription |
        if subscription[:protocol] == type.to_s && subscription[:endpoint] == @subscriber_data[type]
          return subscription[:subscription_arn]
        end
      end
      return nil
    end # get_subscription_status

    # Delete the SNS topic
    def delete_topic
      response = @sns_client.delete_topic(:topic_arn => @topic_data[:arn])
    end # delete_topic
  end # SNSHelper
end
