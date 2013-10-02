# SWF/SNS Sample
#
# See the file called `README.md` for a description of what this file does.
#

# You need this to use the AWS Ruby SDK.
require 'aws-sdk'

require_relative 'utils.rb'
require_relative 'get_contact_activity.rb'
require_relative 'send_sns_activity.rb'

class SampleWorkflow

  attr_accessor :name

  def initialize
    @domain = init_domain

    task_list = get_uuid

    register_workflow(task_list)
    register_activities(task_list)
  end

  # Registers the workflow
  def register_workflow(task_list)
    workflow_name = "swf-sns-workflow-#{task_list}"
    @workflow_type = nil

    options =  {
      :default_task_list => task_list,
      :default_child_policy => :terminate,
      :default_task_start_to_close_timeout => 3600,
      :default_execution_start_to_close_timeout => 24 * 3600 }

    # Check to see if the workflow already exists.
    @domain.workflow_types.each do | w |
      if w.name == workflow_name
        @workflow_type = w
      end
    end

    # a default value...
    workflow_version = '1'

    if @workflow_type
      # the workflow type was found. Check to see if the options are the same.
      options_differ = false
      options.keys.each do | option_type |
        if @workflow_type.send(option_type) != options[option_type]
          options_differ = true
        end
      end
      if options_differ
        # if the options differ, we need to change the version.
        workflow_version = @workflow_type.version
        begin
          # hopefully, it's just a number...
          n = Integer (workflow_version)
          workflow_version = String(n.next)
        rescue
          # ...if not, attempt to split the numeric part of the string from the
          # rest of it
          (workflow_version, n) = workflow_version.partition("\d+")
          n = n.to_i
          workflow_version << String(n.next)
        end
        # options differ, so we'll register the workflow type again
        @workflow_type = nil
      end
    end

    if(@workflow_type.nil?)
      @workflow_type = @domain.workflow_types.create(
        workflow_name, workflow_version, options)
    end
  end

  # Registers all of the activities
  def register_activities(task_list)
    # This list is in order of the operations to be performed.
    activity_sequence = [ GetContactActivity, SendSNSActivity ]

    # reverse the list so that when we push each element onto the stack, we can
    # just pop to get the next activity.
    activity_sequence.reverse!

    # fill the list with objects
    @activity_list = []
    activity_sequence.each { | activity_class |
      @activity_list.push(activity_class.new(@domain, task_list)) }
  end

  # poll for decision tasks
  def poll_for_decisions
    # first, poll for decision tasks...
    @domain.decision_tasks.poll(@workflow_type.default_task_list) do | task |
      task.new_events.each do | event |
        case event.event_type
          when 'WorkflowExecutionStarted'
            task.schedule_activity_task(@activity_list.last.activity_type)
          when 'ActivityTaskCompleted'
            completed_task = @activity_list.pop
            # if this was the final task, then finish the workflow.
            if @activity_list.empty?
              task.complete!
              task.complete_workflow_execution
              return false
            else
              # schedule the next activity, passing any results from the
              # previous activity. Results will be received in the activity
              # task.
              task.schedule_activity_task(
                @activity_list.last.activity_type,
                { :input => event.attributes.result })
            end
          when 'ActivityTaskTimedOut'
            task.complete!
            task.fail_workflow_execution
            return false
          when 'ActivityTaskFailed'
            task.complete!
            task.fail_workflow_execution
            return false
          when 'WorkflowExecutionCompleted'
            task.complete!
            task.workflow_execution.terminate
            return false
        end
      end
      task.complete!
    end
    return true
  end

  def start_execution
    @workflow_type.start_execution

    # start the activity pollers, each on their own process.
    @activity_list.each do | activity |
      fork do
        activity.poll_for_activities
      end
    end

    poll_for_decisions

    # wait for all the sub-processes to complete.
    Process.wait
  end
end

# if the file was run from the command-line, instantiate the class and begin the workflow execution.
if __FILE__ == $0
  sample_workflow = SampleWorkflow.new
  sample_workflow.start_execution
end

