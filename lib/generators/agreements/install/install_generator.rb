# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"
require_relative "../migration_helpers"

module Agreements
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      include MigrationHelpers

      source_root File.expand_path("templates", __dir__)
      desc "Installs the agreement versions and acceptances migration."

      def create_migration_file
        migration_template "create_agreements_tables.rb.tt", "db/migrate/create_agreements_tables.rb"
      end

      def post_install
        say "\nagreements installed. Run `bin/rails db:migrate`.", :green
        say "Define finished agreement versions in host data migrations and seeds."
      end
    end
  end
end
