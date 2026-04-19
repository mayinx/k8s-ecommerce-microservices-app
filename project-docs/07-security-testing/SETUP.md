



## Install Ruby

THough not absolutely necessary ... sicne the ruyb healtcheck module  offers a dockerfile so that a docker image can be executed ... it is useful to have ruby on board to directrly test the behavior ...


### Local Ruby setup for the owned `healthcheck` helper

The local Ruby check in this phase is only needed to validate that the owned helper script can be parsed and started outside the container as well.

~~~bash
# Refresh the local APT package index before installing Ruby packages.
$ sudo apt update

# Install the Ubuntu-managed Ruby toolchain.
# -y = automatically confirm package installation prompts
# ruby-full = Ruby interpreter plus the usual Ruby tooling shipped by Ubuntu
$ sudo apt install -y ruby-full

# Install the required Ruby gem into the current user's gem directory
# instead of the system-wide gem path.
# --user-install = avoid the earlier permission error on /var/lib/gems/...
$ gem install --user-install awesome_print

# Show the active local Ruby version as a quick installation check.
$ ruby -v

# Validate the syntax of the owned healthcheck helper without normal execution.
# -c = syntax check only
$ ruby -c healthcheck/healthcheck.rb

# Start the helper once locally to confirm that it loads successfully.
# In the current script state, running it without -s / --services is expected
# to stop with the message: "no services specified"
$ ruby healthcheck/healthcheck.rb
~~~