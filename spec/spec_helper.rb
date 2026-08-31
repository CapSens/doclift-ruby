require "bundler/setup"

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100
end

require "doclift"
require "webmock/rspec"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.expose_dsl_globally = false
  config.disable_monkey_patching!

  # The gem memoizes global configuration and client: without a reset around
  # every example, a spec's configuration would leak into whichever example
  # the random ordering schedules next.
  config.before { Doclift.reset! }
  config.after { Doclift.reset! }

  config.order = :random
  Kernel.srand config.seed
end
