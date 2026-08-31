require File.join(__dir__, "lib", "doclift", "version")

Gem::Specification.new do |spec|
  spec.name    = "doclift"
  spec.version = Doclift::VERSION
  spec.authors = ["CapSens"]
  spec.email   = ["development@capsens.eu"]

  spec.summary     = "Ruby client for the Doclift document generation API."
  spec.description = [
    "Ruby client for the Doclift document generation API: templates, variables,",
    "document requests (synchronous and asynchronous), workflow templates and",
    "webhook signature verification.",
  ].join(" ")
  spec.license  = "MIT"
  spec.homepage = "https://github.com/CapSens/doclift-ruby"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  spec.required_ruby_version = ">= 3.1.0"

  spec.files = Dir.glob("lib/**/*").select { |path| File.file?(path) } + [
    "CHANGELOG.md", "LICENSE", "README.md",
  ]
  spec.require_paths = ["lib"]

  # logger stops being a default gem in Ruby 4.0, so the dependency must be
  # explicit even though every currently supported Ruby ships it.
  spec.add_dependency "logger", ">= 1.5"

  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "webmock", "~> 3.26"
end
