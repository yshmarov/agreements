# frozen_string_literal: true

require "test_helper"

class AgreementsTest < ActiveSupport::TestCase
  test "finds the current and pending version" do
    user = create_user
    previous = create_version
    current = create_version(version: "2026-09-01")

    assert_equal current, Agreements.current_version("terms")
    assert_equal current, Agreements.pending_version("terms", subject: user)
    assert_not_equal previous, Agreements.current_version("terms")
  end

  test "accepts only the submitted current version" do
    user = create_user
    previous = create_version
    current = create_version(version: "2026-09-01")

    error = assert_raises(Agreements::VersionNotCurrent) do
      Agreements.accept!("terms", version_id: previous.id, subject: user, actor: user, authority: "self")
    end

    assert_equal current, error.current_version
    assert_empty Agreements::Acceptance.all

    acceptance = Agreements.accept!(
      "terms",
      version_id: current.id,
      subject: user,
      actor: user,
      authority: "self"
    )

    assert_equal current, acceptance.agreement_version
    assert_nil Agreements.pending_version("terms", subject: user)
  end

  test "rejects missing malformed and wrong-agreement version ids" do
    user = create_user
    current = create_version
    other = create_version(agreement_key: "dpa")

    [nil, "not-an-id", other.id].each do |version_id|
      error = assert_raises(Agreements::VersionNotCurrent) do
        Agreements.accept!("terms", version_id: version_id, subject: user, actor: user, authority: "self")
      end

      assert_equal current, error.current_version
    end

    assert_empty Agreements::Acceptance.all
  end

  test "requires stable opaque identities" do
    assert_equal "gid://dummy/User/1", Agreements.identity_key("gid://dummy/User/1")
    assert_raises(Agreements::InvalidIdentity) { Agreements.identity_key("") }
    assert_raises(Agreements::InvalidIdentity) { Agreements.identity_key("  ") }
    assert_raises(Agreements::InvalidIdentity) { Agreements.identity_key(Object.new) }
  end
end
