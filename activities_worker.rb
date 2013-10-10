require_relative 'get_contact_activity.rb'
require_relative 'send_sns_activity.rb'
require_relative 'wait_for_sns_activity.rb'
require_relative 'send_result_activity.rb'

class ActivitiesWorker

  def initialize(domain, task_list)
    @domain = domain
    @task_list = task_list
    @activities = {}

    # These are the activities we'll run, in order.
    activity_sequence = [
      GetContactActivity,
      SendSNSActivity,
      WaitForSNSActivity,
      SendResultActivity ]

    activity_sequence.each do | activity_class |
      activity_obj = activity_class.new
      puts "** initialized and registered activity: #{activity_obj.name}"
      # add it to the hash
      @activities[activity_obj.name.to_sym] = activity_obj
    end
  end

  #
  # Polls for activities until the activity is marked complete.
  #
  def poll_for_activities
    @domain.activity_tasks.poll(@task_list) do | task |
      activity_name = task.activity_type.name

      puts("#{activity_name}: #{__method__}")

      # find the task on the activities list, and run it.
      if @activities.key?(activity_name.to_sym)
        activity = @activities[activity_name.to_sym]
        puts "** Starting activity task: #{activity_name}"
        if activity.do_activity(task)
          puts "++ Activity task completed: #{activity_name}"
          task.complete!({ :result => activity.results })
        else
          puts "-- Activity task failed: #{activity_name}"
          task.fail!(
            { :reason => activity.results[:reason],
              :details => activity.results[:detail] } )
        end
      else
        puts "couldn't find key in @activities list: #{activity_name}"
        puts "contents: #{@activities.keys}"
      end
    end
  end
end

# if the file was run from the command-line, instantiate the class and begin the
# activities
if __FILE__ == $0
  if ARGV.count < 1
    puts "Need a task list!"
  else
    worker = ActivitiesWorker.new(init_domain, ARGV[0])
    worker.poll_for_activities
    puts "All done!"
  end
end

