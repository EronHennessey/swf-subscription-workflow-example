require 'aws'
require './console_helper.rb'

module RegistrationExample
  # Sets up a Simple Workflow environment for the RegistrationExample workflow.
  class SWFHelper

    # Create the SWFHelper object and register a domain to launch our workflow in.
    def initialize(domain_name)
      # Define some data associated with the domain.
      @swf = AWS::SimpleWorkflow.new
      @domain_name = domain_name
      @domain_name.freeze # domain_name will not change.

      @activity_names = {
        :subscribe => "#{@domain_name}-subscribe-activity",
        :confirm_email => "#{@domain_name}-confirm-email-activity",
        :confirm_sms => "#{@domain_name}-confirm-sms-activity",
        :send_success => "#{@domain_name}-send-success-activity",
        :send_failure => "#{@domain_name}-send-failure-activity" }
      @activity_objects = {
        :subscribe => nil,
        :confirm_email => nil,
        :confirm_sms => nil,
        :send_success => nil,
        :send_failure => nil }
      @activity_threads = {
        :subscribe => nil,
        :confirm_email => nil,
        :confirm_sms => nil,
        :send_success => nil,
        :send_failure => nil }

      # First, check to see if the domain already exists.
      @domain = @swf.domains[@domain_name]
      if @domain == nil
        # Register the domain for just a day. This is merely a test, after all.
        @domain = @swf.domains.create(@domain_name, 1, { :description => 'RegistrationExample domain' })
      end
    end # initialize

    # Set up the "subscription" workflow
    #
    # @param [Integer] workflow_execution_time_limit
    #   The time limit, in seconds, for the entire workflow.
    #
    # @param [Integer] decision_execution_time_limit
    #   The time limit, in seconds, for any decision task on this workflow.
    #
    def setup_subscription_workflow(workflow_execution_time_limit, decision_execution_time_limit)
      # define some data associated with the workflow.
      @workflow_name = "#{@domain_name}-subscription-workflow"
      @workflow = nil
      @task_list_name = "#{@domain_name}-tasks"
      @task_list_name.freeze

      # Check to see if the workflow already exists.
      @domain.workflow_types.each do | w |
        if w.name == @workflow_name
          @workflow = w
        end
      end

      # Register the workflow
      if @workflow == nil
        @workflow = @domain.workflow_types.register(@workflow_name, "v1", {
          :default_child_policy => :terminate,
          :default_execution_start_to_close_timeout => workflow_execution_time_limit,
          :default_task_list => @task_list_name,
          :default_task_start_to_close_timeout => decision_execution_time_limit,
          :description => "#{@domain_name} subscription workflow"})
      end
    end # setup_workflow

    # Sets up the "subscribe" activity, which is responsible for getting user input (email/phone #).
    def setup_subscribe_activity(
      task_total_time_limit, task_start_time_limit, task_execution_time_limit, heartbeat_time_limit = :none)
      # Register the activity
      @subscribe_activity = nil
      @domain.activity_types.each do | a |
        if(a.name == activity_name)
          @subscribe_activity = a
        end
      end

      if @subscribe_activity == nil
        @subscribe_activity = @domain.activity_types.register(@activity_names[:register], "v1", {
          :default_task_list => @task_list_name,
          :default_task_heartbeat_timeout => heartbeat_time_limit,
          :default_task_schedule_to_start_timeout => task_start_time_limit,
          :default_task_schedule_to_close_timeout => task_total_time_limit,
          :default_task_start_to_close_timeout => task_execution_time_limit,
          :description => "#{@domain_name} start subscription activity"})
      end
    end # setup_start_subscribe_activity

    def begin_workflow_execution
      @workflow_execution = @workflow.start_execution
    end

    def poll_for_workflow_events
      @domain.decision_tasks.poll(@task_list_name) do | decision_task |
      decision_task.new_events.each do | event |
        puts "\nEvent received: #{event.inspect}"
        case event.event_type
          when 'WorkflowExecutionStarted' # Schedule the first activity.
            execution_context = @workflow_execution.latest_execution_context
            puts "Workflow execution context: #{execution_context}"
            if execution_context == nil || execution_context == ""
              puts "Scheduling first activity task!"
              decision_task.schedule_activity_task(@subscribe_activity)
            end
          when 'ActivityTaskScheduled'
            if event.attributes[:name] == @activity_names[:subscribe]
              # start the subscribe activity.
            end
          when 'ActivityTaskCompleted' # Complete this task
            puts "Activity complete!"
            decision_task.complete_workflow_execution(:result => event.attributes.result)
          end
        end
      end
    end
  end # SWFHelper

  # Test the SWFHelper class.
  def self.test_swf_helper
    swf_helper = SWFHelper.new("DataFrobotz")
    puts "Registered domain: DataFrobotz"

    swf_helper.setup_subscription_workflow(3600, 360)
    puts "Registered user subscription workflow"

    swf_helper.setup_start_subscribe_activity(3600, 10, 420)
    puts "Registered subscribe activity"

    puts "Beginning workflow..."
    swf_helper.begin_workflow_execution

    puts "Polling for events..."
    swf_helper.poll_for_workflow_events
  end

end # RegistrationExample

# If this file is run, such as:
#
#     $ ruby swf_helper.rb
#
# The function below will test the class.
RegistrationExample.test_swf_helper

