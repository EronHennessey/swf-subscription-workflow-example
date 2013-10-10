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
    * basic_activity.rb
    * get_contact_activity.rb
    * swf_sns_sample.rb
    * console_interface.rb
    * send_sns_activity.rb
    * utils.rb

3. Run `swf_sns_sample.rb` as shown:

        ruby swf_sns_sample.rb

   The sample should begin running--you will know if you are prompted for your email address and/or phone number.

   **Note:** If you're running ruby outside of Cygwin on Windows, you will get this message:

        swf_sns_sample.rb:142:in `fork': fork() function is unimplemented on this machine (NotImplementedError)
                from swf_sns_sample.rb:142:in `block in start_execution'
                from swf_sns_sample.rb:141:in `each'
                from swf_sns_sample.rb:141:in `start_execution'
                from swf_sns_sample.rb:157:in `<main>'

4. Enter your e-mail and/or phone number for SMS messaging at the prompt. For a valid SMS message address, be sure to
    enter your phone number as all numerals, preceded by country code, such as `12068889999`. This is the first human
    task in the workflow.

5. Wait for a message to appear on any of the addresses that you entered (email or SMS). It will look something like
    this:


## Examining the Code

The code is thoroughly commented and you should be able to get a good understanding of how it works by examining the
source files.

Here is the recommended sequence if you'd like to simply dive right into the code:

1. Start with [utils.rb][code-utils], which contains code that sets up the Amazon SWF domain and is used by other source
    files. It's short and easy to understand.

2. Move onto [swf_sns_sample.rb][code-swf-sns-sample], which contains the workflow and workflow starter code.

3. Next, look at [basic_activity.rb][code-basic-activity]. This file contains code that is common to all of the
    activities in the sample, and provides some uniformity in how they can be called.

4. For an example of a simple human input activity and how it can provide data to the workflow, see the code in
    [get_contact_activity.rb][code-get-content-activity]. It prompts the user for input, and then sends the input back
    to the workflow.

5. See [send_sns_activity.rb][code-send-sns-activity] for code that sets up an Amazon SNS topic and uses the data
    provided by *GetContactActivity* to subcribe the user to the workflow.

[awsaccount]: http://aws.amazon.com/
[awssdk-ruby]: http://aws.amazon.com/sdkforruby/
[awssdk-ruby-config]: http://aws.amazon.com/developers/getting-started/ruby/
[ruby]: https://www.ruby-lang.org/en/
[sns-main]: http://aws.amazon.com/sns/
[sns-topic]: http://docs.aws.amazon.com/AWSRubySDK/latest/AWS/SNS/Topic.html
[swf-main]: http://aws.amazon.com/swf/
[code-utils]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/utils.rb
[code-swf-sns-sample]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/swf_sns_sample.rb
[code-basic-activity]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/basic_activity.rb
[code-get-content-activity]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/get_contact_activity.rb
[code-send-sns-activity]: https://github.com/EronHennessey/swf-subscription-workflow-example/blob/master/send_sns_activity.rb
