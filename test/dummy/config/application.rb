# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "agreements"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path("..", __dir__)
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.active_record.maintain_test_schema = false
    config.action_controller.allow_forgery_protection = false
    config.secret_key_base = "agreements-test-secret-key-base"
    config.hosts.clear
    config.active_support.deprecation = :stderr
  end
end
