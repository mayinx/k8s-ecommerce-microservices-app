## Local Ruby setup for the owned `healthcheck` helper

Ruby is useful for running the Phase 07 healthcheck tests directly on the workstation.

The `healthcheck` helper can also be built and executed through Docker, but local Ruby keeps the edit-test loop faster while working on:

- Ruby syntax checks
- CLI characterization tests
- Ruby unit tests
- Refactoring

### Install Ruby

~~~bash
# Refresh the local APT package index before installing Ruby packages.
sudo apt update

# Install the Ubuntu-managed Ruby toolchain.
# ruby-full = Ruby interpreter plus the usual Ruby tooling shipped by Ubuntu
sudo apt install -y ruby-full

# Show the active local Ruby version as a quick installation check.
ruby -v
~~~

### Validate the Ruby healthcheck helper locally

~~~bash
# Validate the syntax of the owned healthcheck helper without normal execution.
# -c = syntax check only
ruby -c healthcheck/healthcheck.rb

# Start the helper once locally to confirm that it loads successfully.
# Running without --services is expected to stop with:
# "no services specified"
ruby healthcheck/healthcheck.rb
~~~

### Run the Ruby Phase 07 tests

~~~bash
# Run the Ruby CLI characterization and unit tests through the Phase 07 Make target.
make p07-healthcheck-tests
~~~

Note: No extra Ruby gem is required for the final Phase 07 helper path. The earlier `awesome_print` dependency was removed so the helper can emit valid JSON through Ruby's standard `json` library.