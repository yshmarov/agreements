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
      Agreements.accept!("terms", **acceptance_attributes(previous, subject: user))
    end

    assert_equal current, error.current_version
    assert_empty Agreements::Acceptance.all

    acceptance = Agreements.accept!("terms", **acceptance_attributes(current, subject: user))

    assert_equal current, acceptance.agreement_version
    assert_nil Agreements.pending_version("terms", subject: user)
  end

  test "rejects missing malformed and wrong-agreement version ids" do
    user = create_user
    current = create_version
    other = create_version(agreement_key: "dpa")

    [nil, "not-an-id", other.id].each do |version_id|
      error = assert_raises(Agreements::VersionNotCurrent) do
        Agreements.accept!("terms", **acceptance_attributes(current, subject: user, version_id: version_id))
      end

      assert_equal current, error.current_version
    end

    assert_empty Agreements::Acceptance.all
  end

  test "a scheduled version becomes current on its effective date" do
    user = create_user
    current = create_version
    Agreements.accept!("terms", **acceptance_attributes(current, subject: user))
    scheduled = create_version(version: "2026-09-01", effective_at: 14.days.from_now)

    assert_equal current, Agreements.current_version("terms")
    assert_equal scheduled, Agreements.upcoming_version("terms")
    assert_nil Agreements.pending_version("terms", subject: user)
    assert_raises(Agreements::VersionNotCurrent) do
      Agreements.accept!("terms", **acceptance_attributes(scheduled, subject: user))
    end

    travel 14.days + 1.second do
      assert_equal scheduled, Agreements.current_version("terms")
      assert_nil Agreements.upcoming_version("terms")
      assert_equal scheduled, Agreements.pending_version("terms", subject: user)
    end
  end

  test "the version that took effect most recently is current" do
    scheduled = create_version(version: "scheduled", effective_at: 14.days.from_now)
    correction = travel(5.days) { create_version(version: "correction") }

    travel(6.days) { assert_equal correction, Agreements.current_version("terms") }
    travel(15.days) { assert_equal scheduled, Agreements.current_version("terms") }
  end

  test "repeated checks in one request hit the query cache" do
    create_version
    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:cached] || payload[:name] == "SCHEMA" }

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      ActiveRecord::Base.cache { 3.times { Agreements.current_version("terms") } }
    end

    assert_equal 1, queries
  end

  test "requires stable opaque identities" do
    assert_equal "gid://dummy/User/1", Agreements.identity_key("gid://dummy/User/1")
    assert_raises(Agreements::InvalidIdentity) { Agreements.identity_key("") }
    assert_raises(Agreements::InvalidIdentity) { Agreements.identity_key("  ") }
    assert_raises(Agreements::InvalidIdentity) { Agreements.identity_key(Object.new) }
  end
end
