# If this file is run, build the docs for the subscription workflow example for the AWS SDK for Ruby.
#
# Requires [YARD](http://yardoc.org/) to be installed.
#
# @author Eron Hennessey
#

# Builds the Subscription Workflow Example documentation using [Yard](http://www.yardoc.org/).
def build_docs
  system("yard doc --markup markdown *.rb")
end

# Starts a server to view the Subscription Workflow Example documentation using [Yard](http://www.yardoc.org/).
def show_docs
  pid = spawn("yard server")
  Process.detach pid
end

build_docs
show_docs
