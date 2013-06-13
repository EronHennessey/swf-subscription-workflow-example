module SubscriptionWorkflowExample
  # A generic activity class.
  class GenericActivity

    # Creates a new GenericActivity
    #
    def initialize(domain, workflow)
      @domain = domain
      @workflow = workflow
    end

    # Sets the thread that is running {#start} on this activity.
    #
    # @param thread
    #   The thread that will run this activity.
    #
    def set_thread(thread)
      @thread = thread
    end

    # Starts the activity.
    # @todo override this in your derived class, then call it to start the activity.
    def start
    end
  end
end

