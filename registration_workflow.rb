require 'aws'

# The RegistrationWorkflowSample demonstrates a simple site registration workflow in Ruby, using the AWS SDK for Ruby,
# Amazon Simple Workflow and Amazon Simple Notification Service.
#
# The workflow is:
#
# 1. The user runs the program and a new workflow is generated
# 2. The first activity queries the user for an email address and/or phone number.
# 3. The second activity creates an sns topic and attempts to register the user with it.
# 4. The third and fourth activities wait for the customer to confirm registration by either email or phone.
# 5. The final activity removes any remaining sns confirmation requests, and then uses the same sns topic to notify the
#    user of success.
# 6. The workflow ends.
#
class RegistrationWorkflowSample

  def initialize
    @user_data = {} # data about the user, such as email/phone info.
    @sns_data = {} # data about Amazon SNS.
  end

  # Registers the user with either a name or phone number, or both.
  #
  # @return [Hash]
  #   The entered email and phone values in a hash using the keys `:email` and `:phone`. If a value was not entered, it
  #   will be `nil`.
  #
  #   Example:
  #     { :email => "me@example.com", :phone => "12345678910" }
  #
  def start_registration
    puts "#=============================================#"
    puts "|                                             |"
    puts "|          Welcome to Data-Frobotz!           |"
    puts "|                                             |"
    puts "#---------==========================----------#"
    puts "|                                             |"
    puts "| You can register with either:               |"
    puts "|                                             |"
    puts "| * your email address                        |"
    puts "| * your phone number                         |"
    puts "|                                             |"
    puts "| Note: your phone must be able to accept SMS |"
    puts "| messages to confirm by phone.               |"
    puts "|                                             |"
    puts "#=============================================#"
    puts "                                               "
    puts "Please enter one, or both, of these values now."
    puts "                                               "
    return_values = { :email => nil, :phone => nil }
    return_values[:email] = query_user_with_confirmation("Email address")
    return_values[:phone] = query_user_with_confirmation("Phone number")
    return_values
  end

  # Create the SNS topic
  #
  # @return
  #   The SNS topic Amazon Resource Name (ARN)
  #
  def create_sns_topic
    # create a new SNS topic and get the Amazon Resource Name (ARN).
    response = @sns_client.create_topic(:name => "DataFrobotz")
    @topic_arn = response[:topic_arn]

    # For an SMS notification, setting DisplayName is *required*. Note that only the first 10 characters of the
    # DisplayName will be shown on the SMS message sent to the user.
    response = @sns_client.set_topic_attributes({
      :topic_arn => @topic_arn,
      :attribute_name => "DisplayName",
      :attribute_value => "DataFrobtz" })

    @topic_arn
  end

  # Subscribe the user to the sns topic.
  #
  # @param [Hash] user_data
  #   A hash containing the user's email and/or phone number.
  #
  def subscribe_sns_topic(user_data)
    if user_email != nil
      # subscribe to the topic via email
      response = @sns_client.subscribe({
        :topic_arn => topic_arn,
        :protocol => "email",
        :endpoint => user_email})
      @subscription_arns[:email] = response[:subscription_arn]
    end

    if user_phone != nil
      # subscribe to the topic via SMS
      response = @sns_client.subscribe({
        :topic_arn => topic_arn,
        :protocol => "sms",
        :endpoint => phone})
      @subscription_arns[:phone] = response[:subscription_arn]
    end
  end

  # Wait for the user to respond.
  #
  def wait_for_response(user_data)
  end

  # Set up a workflow
  #
  def set_up_workflow
    
  end
end

