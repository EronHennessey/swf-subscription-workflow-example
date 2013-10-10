require 'aws-sdk'
require 'securerandom'

# SMS Messaging (which can be used by Amazon SNS) is available only in the
# `us-east-1` region.
$SMS_REGION = 'us-east-1'
AWS.config({ :region => $SMS_REGION })

# Used to get a different task list name every time we start a new workflow
# execution.
#
# This avoids issues if our pollers re-start before SWF considers them closed,
# causing the pollers to get events from previously-run executions.
def get_uuid
  SecureRandom.uuid
end

# Registers the domain that the workflow will run in.
def init_domain
  domain_name = 'SWFSampleDomain'
  domain = nil
  swf = AWS::SimpleWorkflow.new

  # First, check to see if the domain already exists and is registered.
  swf.domains.registered.each do | d |
    if(d.name == domain_name)
      domain = d
      break
    end
  end

  if domain.nil?
    # Register the domain for one day.
    domain = swf.domains.create(domain_name, 1, { :description => "#{domain_name} domain" })
  end

  return domain
end

