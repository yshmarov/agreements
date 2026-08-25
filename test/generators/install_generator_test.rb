# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/agreements/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Agreements::Generators::InstallGenerator
  destination File.expand_path("../tmp/generator", __dir__)
  setup :prepare_destination

  test "creates only the evidence migration" do
    run_generator

    assert_migration "db/migrate/create_agreements_tables.rb" do |migration|
      assert_includes migration, "create_table :agreements_versions"
      assert_includes migration, "create_table :agreements_acceptances"
      assert_includes migration, "foreign_key: { to_table: :agreements_versions }"
      assert_includes migration, "index_agreements_acceptances_on_version_and_subject"
    end
    assert_no_file "config/initializers/agreements.rb"
    assert_no_file "config/routes.rb"
  end

  test "follows a host configured for UUID primary keys" do
    generator_options = Rails.configuration.generators.options[:active_record]
    generator_options[:primary_key_type] = :uuid

    run_generator

    assert_migration "db/migrate/create_agreements_tables.rb" do |migration|
      assert_includes migration, "create_table :agreements_versions, id: :uuid"
      assert_includes migration, "create_table :agreements_acceptances, id: :uuid"
      assert_includes migration, "foreign_key: { to_table: :agreements_versions }, type: :uuid"
    end
  ensure
    generator_options&.delete(:primary_key_type)
  end
end
