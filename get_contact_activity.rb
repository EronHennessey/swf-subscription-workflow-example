#
# **GetContactActivity** provides a prompt for the user to enter contact information. When the user successfully enters
# contact information, the activity is complete.
#
require 'yaml'
require_relative 'basic_activity.rb'

# An activity that prompts the user for subscription information.
class GetContactActivity < BasicActivity

  def initialize
    super('get_contact_activity', 'v1')
  end

  def prompt_with_confirmation(prompt_text = "")
    confirmed = :false
    user_text = nil
    while confirmed == :false

      # get the user's input for the field.
      print "#{prompt_text}: "
      user_text = $stdin.gets.strip

      # if the user types ':exit', exit and return nil.
      if user_text == ':exit'
        return nil
      end

      # confirm the choice.
      puts "You entered: #{user_text}"
      print "Use this value? (y/n): "
      confirmation = $stdin.gets.strip.downcase
      if confirmation == 'y'
        confirmed = :true
      else
        if confirmation.start_with?("y")
          puts "You can enter only 'y' or 'Y' to confirm your choice."
          puts "Extra characters in the response aren't recognized."
        else
          puts "Please re-enter your input, or type ':exit' to cancel input."
        end
      end
    end
    return user_text
  end

  # Get some data to use to subscribe to the topic.
  def do_activity(task)
    puts("#{__method__} #{task.inspect}")
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

