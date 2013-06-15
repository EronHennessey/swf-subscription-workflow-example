require './sns_helper.rb'
require './console_interface.rb'

# A test for the SNSHelper class

# Create a new instance of SNSHelper and create a test SNS topic.
sns_helper = SubscriptionWorkflowExample::SNSHelper.new('SNSHelperTest', 'SNSHelper')
sns_helper.create_topic

# Get some data to use to subscribe to the topic.
puts "Please enter your email address and/or your phone number to confirm your subscription."
puts "If you enter a phone number, it must be able to receive SMS messages to confirm."
email = SubscriptionWorkflowExample::ConsoleInterface.prompt_with_confirmation("\nEMail")
phone = SubscriptionWorkflowExample::ConsoleInterface.prompt_with_confirmation("\nPhone")

# Subscribe!
sns_helper.subscribe_topic(email, phone)

# You can check the subscription status as many times as you like, or exit
# by entering 'n'.
check_subscription = 'y'
while(check_subscription == 'y')
  print "\nCheck topic subscription status? (y/n): "
  check_subscription = gets.strip.downcase
  if check_subscription == 'y'
    puts "Email: #{email}"
    puts "  " << sns_helper.get_subscription_status(:email).to_s
    puts "Phone: #{phone}"
    puts "  " << sns_helper.get_subscription_status(:sms).to_s
  end
end

# Since this is just a test, clean up the SNS topic if the user desires (or
# you can keep it running and add new subscriptions to it by re-running the
# test with different data).
print "Delete SNS topic? (y/n): "
if(gets.downcase == 'y')
  sns_helper.delete_topic
end
