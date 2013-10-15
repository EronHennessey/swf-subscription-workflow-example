require 'yaml'
require_relative 'basic_activity.rb'

#
# **GetContactActivity** provides a prompt for the user to enter contact
# information. When the user successfully enters contact information, the
# activity is complete.
#
# This activity returns the following results, in YAML text format:
#
# * on success: { :email => *email*, :sms => *sms* }
#
# Either value can be nil or an empty string.
#
class GetContactActivity < BasicActivity

  # initialize the activity
  def initialize
    super('get_contact_activity', 'v1')
  end

  # Get some data to use to subscribe to the topic.
  def do_activity(task)
    puts ""
    puts "Please enter either an email address or SMS message (mobile phone) number to"
    puts "receive SNS notifications. You can also enter both to use both address types."
    puts ""
    puts "If you enter a phone number, it must be able to receive SMS messages, and must"
    puts "be 11 digits (such as 12345678901 to represent the number 1-234-567-8901)."

    input_confirmed = false
    while !input_confirmed
      puts ""
      print "Email: "
      email = $stdin.gets.strip

      print "Phone: "
      phone = $stdin.gets.strip

      puts ""
      if (email == '') && (phone == '')
        print "You provided no subscription information. Quit? (y/n)"
         confirmation = $stdin.gets.strip.downcase
         if confirmation == 'y'
           return false
         end
      else
         puts "You entered:"
         puts "  email: #{email}"
         puts "  phone: #{phone}"
         print "\nIs this correct? (y/n): "
         confirmation = $stdin.gets.strip.downcase
         if confirmation == 'y'
           input_confirmed = true
         end
      end
    end

    # make sure that @results is a single string. YAML makes this easy.
    @results = { :email => email, :sms => phone }.to_yaml

    return true
  end
end

