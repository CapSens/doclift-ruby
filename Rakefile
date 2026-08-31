require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

Rake::Task["release"].clear

desc "Refuses: this gem is not published on RubyGems"
task :release do
  abort([
    "This gem is not published on RubyGems: consumers install it from this",
    "repository, pinned to a tag. See the Releasing section of the README.",
  ].join(" "))
end

task default: [:spec]
