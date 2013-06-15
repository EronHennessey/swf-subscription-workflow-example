# Subscription Workflow Example for the AWS SDK for Ruby

This is an example of a site subscription workflow using [Amazon Simple Workflow
Service (Amazon SWF)][aws-swf], [Amazon Simple Notification Service (Amazon
SNS)][aws-sns], and the [AWS SDK for Ruby][aws-rubysdk].

It emulates a site that allows users to subscribe to notifications from a site
via email or SMS. **Amazon SWF** is used to process the workflow which includes:

* human input (supplying subscription info),
* queries to **Amazon SNS** (did the user confirm the subscription?),
* feedback to the user through his or her chosen notification method.

## Running the example

To run the example, you'll need both [Ruby][] and the [AWS SDK for
Ruby][aws-rubysdk] installed on your system. Once you've done that, you can open
your system's terminal window, go to the directory where you've unpacked the
[.zip download][code-download], and execute the `console_interface_test.rb`
file:

    ruby console_interface_test.rb

## About the code

To see detailed (and hopefully, insightful) documentation about the [example
code][code-repo], you'll need to follow the steps to run the example, but instead of
executing the `console_interface_test.rb` file, execute `show_docs.rb` instead:

    ruby show_docs.rb

which uses [YARD][] to build the docs and then start a web-server to see the
documentation using your [web-browser of choice][browserlist].

## For more information

For more information about what's not covered here, see the documentation for
each of the technologies used:

* [Amazon Simple Workflow Service (Amazon SWF) Documentation][aws-swf-docs]
* [Amazon Simple Notification Service (SNS) Documentation][aws-sns-docs]
* [AWS SDK for Ruby Documentation][aws-rubysdk]
* [YARD Guides & Resources][yard-docs]
* [Ruby Documentation][ruby]

[aws-rubysdk]: http://aws.amazon.com/sdkforruby/
[aws-rubysdk-docs]: http://aws.amazon.com/documentation/sdkforruby/

[aws-swf]: http://aws.amazon.com/swf/
[aws-swf-docs]: http://aws.amazon.com/documentation/swf/

[aws-sns]: http://aws.amazon.com/sns/
[aws-sns-docs]: http://aws.amazon.com/documentation/sns/

[yard]: http://yardoc.org/
[yard-docs]: http://yardoc.org/guides/index.html

[ruby]: http://www.ruby-lang.org/
[ruby-docs]: http://www.ruby-lang.org/en/documentation/

[browserlist]: http://en.wikipedia.org/wiki/List_of_web_browsers

[code-repo]: https://github.com/EronHennessey/swf-subscription-workflow-example
[code-download]: https://github.com/EronHennessey/swf-subscription-workflow-example/archive/master.zip

