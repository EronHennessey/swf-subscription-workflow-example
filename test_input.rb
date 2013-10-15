require 'yaml'

puts "\nPlease enter your email address and/or your phone number to confirm your"
puts "subscription."
puts "\nIf you enter a phone number, it must be able to receive SMS messages, and should"
puts "be 11 digits, such as 12345678901 to represent the number 1-234-567-8901."

input_confirmed = false
while !input_confirmed
  puts ""
  print "Email: "
  email = $stdin.gets.strip

  print "Phone: "
  phone = $stdin.gets.strip

  puts ""
  puts "You entered:"
  puts "  email: #{email}"
  puts "  phone: #{phone}"
  print "\nIs this correct? (y/n): "
  confirmation = $stdin.gets.strip.downcase
  if confirmation == 'y'
    input_confirmed = true
  end
end

# make sure that @results is a single string. YAML makes this easy.
@results = { :email => email, :sms => phone }.to_yaml

puts "\nresults:"
puts @results

