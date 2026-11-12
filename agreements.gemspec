# frozen_string_literal: true

require_relative "lib/agreements/version"

Gem::Specification.new do |spec|
  spec.name = "agreements"
  spec.version = Agreements::VERSION
  spec.authors = ["Yaroslav Shmarov"]
  spec.email = ["yashm@outlook.com"]

  spec.summary = "Record who accepted which version of your Terms, Privacy Notice or DPA, " \
                 "and ask again when they change."
  spec.description = <<~DESCRIPTION
    Versioned acceptance of legal agreements for Rails. Stores which version
    and which localized sentence was accepted, by whom, for whom (a user or a
    company), under what authority and when. Redirects users who still have to
    accept, supports a notice period before new terms take effect, and rejects
    submissions of an outdated version. Two tables, no UI, no external services.
    In production at EthicsPortal.
  DESCRIPTION
  spec.homepage = "https://github.com/yshmarov/agreements"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}/tree/main"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "#{spec.homepage}#readme"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "app/**/*",
    "lib/**/*",
    "CHANGELOG.md",
    "MIT-LICENSE",
    "README.md",
    "SECURITY.md"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "actionpack", ">= 7.1", "< 9"
  spec.add_dependency "activerecord", ">= 7.1", "< 9"
  spec.add_dependency "globalid", ">= 1.0"
  spec.add_dependency "railties", ">= 7.1", "< 9"
end
