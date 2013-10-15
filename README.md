# Passing Data with Human Tasks, Using Amazon SWF with Amazon SNS

[Amazon Simple Workflow (SWF)][swf-main] allows you to define activities in a workflow to be just about anything you can
dream up. In practice, these are generally either computational activities, relying on data-gathering and computation
performed by computers, but "human tasks" are also frequently employed in activities, relying on a living, breathing
human to perform an action and then to signal its completion.

In workflows, another common interaction with humans happens when the workflow must signal the human that something has
occured--a package has been shipped, the dog has been walked, and so forth. Here's where Amazon Simple Notification
Service (SNS) comes in...

[Amazon SNS][sns-main] allows you to subscribe to what is termed a 'topic' that can send messages to its subscribers by
a number of different protocols, among them: email addresses and SMS addresses (frequently mobile phone numbers).

This sample provides an example of a "human task"-style workflow which uses SNS to communicate with the user about the
status of the workflow. It uses the AWS SDK for Ruby, but many of the techniques used here apply to Amazon SWF in
general. The architecture of the underlying HTTP-based service is represented in each of the AWS SDKs.

The AWS Flow Framework provides a somewhat different, simpler way to work with Amazon SWF, and is also available for
Ruby. In fact, the AWS Flow Framework for Ruby is *built upon* the AWS SDK for Ruby, so what you learn here can be
leveraged even if you want to use the AWS Flow Framework for your own workflows.

## Prerequisites

To run the sample, you'll need an [Amazon Web Services (AWS) account][awsaccount], a [Ruby interpreter][ruby], and the
[AWS SDK for Ruby][awssdk-ruby]. This sample should run on Ruby versions 1.9+ and any recent AWS SDK version.

You must also have your AWS Access keys set up as per the [AWS SDK for Ruby Getting Started][awssdk-ruby-config] page.

## Downloading and Running the Sample

To download a .zip archive of the source code for the sample and this README, use this link:

* <https://github.com/EronHennessey/swf-subscription-workflow-example/archive/master.zip>

*To run the sample*

1. Extract the archive to any directory on your computer (see the [Prerequisites](#prerequisites) for information about
    what additional software you may need to successfully run it).

2. Open a terminal (command prompt) and change to the directory where you extracted the source. You should have the following files:

    * README.md
    * activities_worker.rb
    * basic_activity.rb
    * get_contact_activity.rb
    * send_result_activity.rb
    * subscribe_topic_activity.rb
    * swf_sns_sample.rb
    * utils.rb
    * wait_for_confirmation_activity.rb

3. Run `swf_sns_sample.rb` as shown:

        ruby swf_sns_sample.rb

   The sample will begin running and then stop, waiting for you to start the activity worker:

        Amazon SWF Example
        ------------------

        Start the activity worker, preferably in a separate command-line window, with
        the following command:

        > ruby activities_worker.rb cf423e09-c50d-4ffa-9df6-43bb23d3ad69-activities

        You can copy & paste it if you like, just don't copy the '>' character.

        Press return when you're ready...

4. Open a new terminal window or tab (it can even be on a different computer), and run the activity worker using the
   *same line* that is provided in the message. The UUID will change each time you run `swf_sns_sample.rb` (and
   represents the task list name). For example:

        ruby activities_worker.rb cf423e09-c50d-4ffa-9df6-43bb23d3ad69-activities

   The activities worker will now begin running, and its first activity will prompt you for an email and phone number.

5. Enter your e-mail and/or phone number for SMS messaging at the prompt. For a valid SMS message address, be sure to
    enter your phone number as all numerals, preceded by country code, such as `12068889999`. This is the first human
    task in the workflow.

6. Wait for a message from Amazon SNS to appear on any of the addresses that you entered (email or SMS). It will look
   something like this:


## Examining the Code

The code is thoroughly commented and you should be able to get a good understanding of how it works by examining the
source files.

Here is the recommended sequence if you'd like to simply dive right into the code:

1. Start with [utils.rb][code-utils], which contains code that sets up the Amazon SWF domain and is used by other source
   files. It's short and easy to understand.

2. Move onto [swf_sns_sample.rb][code-swf-sns-sample], which contains the workflow and workflow starter code.

3. Next, look at [activities_worker.rb][code-activities-worker]. This code polls for activity events and launches the
   activities based on information coming from Amazon SWF.

4. Now, look at [basic_activity.rb][code-basic-activity]. This file contains code that is common to *all* of the
   activities in the sample, and provides some uniformity in how they can be called. The activities are called in this
   order:

    a. [get_contact_activity.rb][code-get-contact-activity] is an example of a simple human input activity and how it
       can provide data to the workflow. It prompts the user for input, and then sends the input back to the workflow.

    b. [subscribe_topic_activity.rb][code-subscribe-topic-activity] sets up an Amazon SNS topic and uses the data
       provided by *GetContactActivity* to subcribe the user to the workflow.

    c. [wait_for_confirmation_activity.rb][code-wait-for-confirmation-activity] waits for the user to confirm the
       subscription using at least one of the addresses input during *GetContactActivity*.

    d. [send_result_activity.rb][code-send-result-activity] uses the confirmed topic subscription to send the user
       a note by simply publishing it to the topic, concluding the workflow.

## For More Information

For more information about Amazon SWF, Amazon SNS, and the AWS SDK for Ruby, have a look at this fine documentation:

* [Amazon Simple Workflow Service Developer Guide][swfdg]
* [Amazon Simple Notification Service Developer Guide][snsdg]
* [AWS SDK for Ruby Developer Guide][rubysdkdg]
* [AWS SDK for Ruby API Reference][rubysdkref]

[swfdg]: http://docs.aws.amazon.com/amazonswf/latest/developerguide/
[snsdg]: http://docs.aws.amazon.com/sns/latest/dg/welcome.html
[rubysdkdg]: http://docs.aws.amazon.com/AWSSdkDocsRuby/latest/DeveloperGuide/welcome.html
[rubysdkref]: http://docs.aws.amazon.com/AWSRubySDK/latest/frames.html
[awsaccount]: http://aws.amazon.com/
[awssdk-ruby-config]: http://aws.amazon.com/developers/getting-started/ruby/
[awssdk-ruby]: http://aws.amazon.com/sdkforruby/
[code-activities-worker]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/activities_worker.rb
[code-basic-activity]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/basic_activity.rb
[code-get-contact-activity]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/get_contact_activity.rb
[code-send-result-activity]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/send_result_activity.rb
[code-subscribe-topic-activity]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/subscribe_topic_activity.rb
[code-swf-sns-sample]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/swf_sns_sample.rb
[code-utils]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/utils.rb
[code-wait-for-confirmation-activity]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/wait_for_confirmation_activity.rb
[ruby]: https://www.ruby-lang.org/en/
[sns-main]: http://aws.amazon.com/sns/
[sns-topic]: http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SNS/Topic.html
[swf-main]: http://aws.amazon.com/swf/

