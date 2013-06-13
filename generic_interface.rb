module SubscriptionWorkflowExample
  # A generic interface class. The workflow sample could implement additional user interfaces, so long as they obey this
  # model.
  class GenericInterface

    # Obtains the user's email, phone number, or both.
    #
    # @return [Hash]
    #   The entered email and phone values in a hash using the keys `:email` and `:sms`. If a value was not entered, it
    #   will be `nil`.
    #
    #   Example:
    #     { :email => "me@example.com", :phone => "12345678910" }
    #
    def get_subscription_data
      # TODO: overload this function in your derived class!
      # the base class simply returns 'none' for both values.
      return { :email => 'none', :phone => 'none' }
    end

    # Obtains one of the user's subscription credentials. This could be either the phone number or email.
    #
    # @return [String]
    #   The subscriber information that the user entered.
    #
    def get_subscriber_info
      # TODO: overload this function in your derived class!
      # the base class simply returns 'none'.
      return 'none'
    end

    # Displays the interface's "splash screen", or initial interface.
    #
    def show_splash
      # TODO: overload this function in your derived class!
      # This method returns nothing.
    end
  end
end

