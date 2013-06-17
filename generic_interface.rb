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
    # @todo Override this in your derived class!
    #
    def get_subscriber_data
      raise 'This must be overloaded in a derived class!'
    end

    # Obtains one of the user's subscription credentials. This could be either the phone number or email.
    #
    # @return [String]
    #   The subscriber information that the user entered.
    #
    # @todo Override this in your derived class!
    #
    def get_subscriber_info
      raise 'This must be overloaded in a derived class!'
    end

    # Displays the interface's "splash screen", or initial interface.
    #
    # @return [nil]
    #
    # @todo Override this in your derived class!
    #
    def show_splash
      raise 'This must be overloaded in a derived class!'
    end

    # Prompts the user and confirms the choice.
    #
    # @param [String] prompt_text
    #   Some text to prompt the user with. For example: "Name"
    #
    # @return [String]
    #   The text that the user entered.
    #
    # @todo Override this in your derived class!
    #
    def self.prompt_with_confirmation(prompt_text = "")
      raise 'This must be overloaded in a derived class!'
    end
  end
end

