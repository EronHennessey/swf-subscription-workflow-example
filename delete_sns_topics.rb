#
# Lists, and optionally, deletes Amazon SNS topics in a particular AWS region.
#
require 'aws'

aws_region = AWS.config.region

# We allow one argument, the region.
if ARGV.length > 0
  aws_region = ARGV.shift
end

puts "Looking for topics in #{aws_region}..."
sns_client = AWS::SNS::Client.new(:config => AWS.config.with(:region => aws_region))

# list topics.
response = sns_client.list_topics

if response[:topics].size == 0
   puts "* no topics found!"
   exit
end

puts "Topics:"
response[:topics].each do | r |
   puts "* " << r[:topic_arn]
   print "Delete topic? (y/n): "
   if gets.strip.downcase == 'y'
      sns_client.delete_topic(r)
      puts "Topic deleted!"
   else
      puts "OK, keeping topic."
   end
end

