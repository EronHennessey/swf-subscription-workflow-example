require 'aws'
require './generic_workflow.rb'

module SubscriptionWorkflowExample

  # An activity that collects subscription information from the user.
  class GetSubscriptionInfoActivity < GenericActivity

    # Starts the subscribe-user activity.
    def initialize(domain, workflow, interface)
      super(domain, workflow)
      @interface = interface
      @domain.activity_types.create('subscribe-user', '1',
        :default_task_list => @workflow.default_task_list,
        :default_heartbeat_timeout => :none,
        :default_task_schedule_to_start_timeout => 60,
        :default_task_schedule_to_close_timeout => 3660,
        :default_task_start_to_close_timeout => 3600,
        :description => "#{@domain.name} start subscription activity")
    end

    # Starts the subscribe-user activity.
    def start
      subscription_data = @interface.get_subscription_data
    end
  end

  # An activity that waits for confirmation of the user's email address.
  class ConfirmEmailActivity < GenericActivity

    # Creates the confirm-user-email activity.
    def initialize(domain, workflow, interface)
      super(domain, workflow)
      @interface = interface
      @domain.activity_types.create('confirm-user-email', '1',
        :default_task_list => @workflow.default_task_list,
        :default_heartbeat_timeout => :none,
        :default_task_schedule_to_start_timeout => 60,
        :default_task_schedule_to_close_timeout => 3660,
        :default_task_start_to_close_timeout => 3600)
    end

    # Starts the confirm-user-email activity.
    def start
    end
  end

  # An activity that waits for confirmation of the user's SMS phone number.
  class ConfirmSMSActivity < GenericActivity

    # Creates the confirm-user-phone activity.
    def initialize(domain, workflow, interface)
      super(domain, workflow)
      @interface = interface
      @domain.activity_types.create('confirm-user-phone', '1',
        :default_task_list => @workflow.default_task_list,
        :default_heartbeat_timeout => :none,
        :default_task_schedule_to_start_timeout => 60,
        :default_task_schedule_to_close_timeout => 3660,
        :default_task_start_to_close_timeout => 3600)
    end

    # Starts the confirm-user-phone activity.
    def start
    end
  end

  # An activity that sends a success notification to the user, using either the email address or phone number that was
  # confirmed by the confirm-user-email or confirm-user-phone activities.
  class SendSubscriptionSuccessActivity < GenericActivity

    # Creates the send-success activity.
    def initialize(domain, workflow, interface)
      super(domain, workflow)
      @interface = interface
      @domain.activity_types.create('send-success', '1',
        :default_task_list => @workflow.default_task_list,
        :default_heartbeat_timeout => :none,
        :default_task_schedule_to_start_timeout => 60,
        :default_task_schedule_to_close_timeout => 3660,
        :default_task_start_to_close_timeout => 3600)
    end

    # Starts the send-success activity.
    def start
    end
  end

  # Handles execution of the subscribe workflow.
  class SubscribeWorkflow < GenericWorkflow
    # The subscription workflow looks like this:
    #
    # activities = [ get_subscription_info, [ confirm_email, confirm_sms, :or ], send_subscription_success ]
    #
    def initialize(domain, task_list, generic_interface)
      get_subscription_info = GetSubscriptionInfoActivity.new
      activities = [ get_subcription_info, [ confirm_email, confirm_sms, :or ], send_subscription_success ]
      super(domain, task_list, activities)
    end
  end
end

