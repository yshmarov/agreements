# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "dummy/config/environment"
require "rails/test_help"

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :agreements_versions, force: true do |t|
    t.string :agreement_key, null: false
    t.string :version, null: false
    t.text :acceptance_statement, null: false
    t.json :documents, null: false, default: []
    t.timestamps
    t.index %i[agreement_key version], unique: true
    t.index %i[agreement_key created_at]
  end

  create_table :agreements_acceptances, force: true do |t|
    t.references :agreement_version,
                 null: false,
                 index: false,
                 foreign_key: { to_table: :agreements_versions }
    t.string :subject_key, null: false
    t.string :actor_key, null: false
    t.string :authority, null: false
    t.text :acceptance_statement, null: false
    t.string :locale, null: false
    t.datetime :accepted_at, null: false
    t.timestamps
    t.index %i[agreement_version_id subject_key],
            unique: true,
            name: "index_agreements_acceptances_on_version_and_subject"
    t.index :subject_key
  end
end

module ActiveSupport
  class TestCase
    self.use_transactional_tests = true

    private

    def create_version(**attributes)
      defaults = {
        agreement_key: "terms",
        version: "2026-08-16",
        acceptance_statement: "I accept the Terms of Service.",
        documents: [{ title: "Terms of Service", url: "https://example.com/terms" }]
      }
      Agreements::Version.create!(defaults.merge(attributes))
    end

    def create_user(name: "Ada")
      User.create!(name: name)
    end

    def acceptance_attributes(version, subject:, **overrides)
      {
        version_id: version.id,
        subject: subject,
        actor: subject,
        authority: "self",
        acceptance_statement: version.acceptance_statement,
        locale: "en"
      }.merge(overrides)
    end
  end
end
