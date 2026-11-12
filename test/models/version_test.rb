# frozen_string_literal: true

require "test_helper"

class VersionTest < ActiveSupport::TestCase
  test "validates external HTTPS document references" do
    version = Agreements::Version.new(
      agreement_key: "terms",
      version: "one",
      acceptance_statement: "I accept.",
      documents: [{ title: "Terms", url: "http://example.com/terms" }]
    )

    assert_not version.valid?
    assert version.errors.added?(:documents, :invalid)
  end

  test "accepts symbol keys and an optional SHA-256 digest" do
    version = create_version(
      documents: [{ title: "Terms", url: "https://example.com/terms", sha256: "a" * 64 }]
    )

    assert_predicate version, :persisted?
  end

  test "accepts a stable document key for localized links" do
    version = create_version(documents: [{ key: "terms_of_service", title: "Terms", url: "https://example.com/terms" }])

    assert_predicate version, :persisted?
    assert_not create_version_with_document_key("Terms of Service").valid?
  end

  test "rejects unknown document metadata and malformed digests" do
    version = Agreements::Version.new(
      agreement_key: "terms",
      version: "one",
      acceptance_statement: "I accept.",
      documents: [{ title: "Terms", url: "https://example.com/terms", sha256: "no", locale: "en" }]
    )

    assert_not version.valid?
    assert version.errors.added?(:documents, :invalid)
  end

  test "is immutable after creation" do
    version = create_version

    assert_raises(ActiveRecord::ReadOnlyRecord) { version.update!(acceptance_statement: "Changed") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { version.destroy! }
    assert_raises(ActiveRecord::ReadOnlyRecord) { version.delete }
  end

  private

  def create_version_with_document_key(key)
    Agreements::Version.new(
      agreement_key: "terms",
      version: "two",
      acceptance_statement: "I accept.",
      documents: [{ key: key, title: "Terms", url: "https://example.com/terms" }]
    )
  end
end
