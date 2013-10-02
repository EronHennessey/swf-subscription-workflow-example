#
# **GetContactActivity** provides a prompt for the user to enter contact information. When the user successfully enters
# contact information, the activity is complete.
#
require 'yaml'
require_relative 'console_interface.rb'
require_relative 'basic_activity.rb'

# An activity that prompts the user for subscription information.
class GetContactActivity < BasicActivity

  def initialize(domain, task_list)
    super(domain, task_list, 'get_contact_activity')
  end

  # Get some data to use to subscribe to the topic.
  def do_activity(input = nil)
    puts "#{self.class}##{__method__}"

    subscriber_data = { :email => nil, :sms => nil }

    puts "\nPlease enter your email address and/or your phone number to confirm your subscription."
    puts "\nIf you enter a phone number, it must be able to receive SMS messages to confirm."

    subscriber_data[:email] = prompt_with_confirmation("\nEMail")
    subscriber_data[:sms] = prompt_with_confirmation("\nPhone")

    # make sure that @results is a single string.
    @results = subscriber_data.to_yaml
    return true
  end
end
