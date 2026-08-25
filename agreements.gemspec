# frozen_string_literal: true

require_relative "lib/agreements/version"

Gem::Specification.new do |spec|
  spec.name = "agreements"
  spec.version = Agreements::VERSION
  spec.authors = ["Yaroslav Shmarov"]
  spec.email = ["yaroslav.shmarov@clickfunnels.com"]

  spec.summary = "Auditable acceptance of externally hosted legal agreements for Rails."
  spec.description = <<~DESCRIPTION
    A small Rails engine that stores immutable external agreement-version
    metadata and append-only acceptance evidence. It distinguishes the subject
    bound by an agreement from the actor accepting under recorded authority,
    rejects stale rendered versions, and leaves documents, authentication,
    authorization, routes, and UI in the host application.
  DESCRIPTION
  spec.homepage = "https://github.com/yshmarov/agreements"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "app/**/*",
    "lib/**/*",
    "AGENTS.md",
    "CHANGELOG.md",
    "MIT-LICENSE",
    "README.md",
    "SECURITY.md"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.1", "< 9"
end
