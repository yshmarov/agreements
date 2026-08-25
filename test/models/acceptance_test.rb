# frozen_string_literal: true

require "test_helper"

class AcceptanceTest < ActiveSupport::TestCase
  test "records subject actor authority and server time" do
    version = create_version
    subject = create_user(name: "Organization")
    actor = create_user(name: "Owner")

    acceptance = Agreements.accept!(
      "terms",
      version_id: version.id,
      subject: subject,
      actor: actor,
      authority: "organization_owner"
    )

    assert_equal subject.to_global_id.to_s, acceptance.subject_key
    assert_equal actor.to_global_id.to_s, acceptance.actor_key
    assert_equal "organization_owner", acceptance.authority
    assert_in_delta Time.current, acceptance.accepted_at, 1.second
  end

  test "retries return the original evidence" do
    version = create_version
    subject = create_user(name: "Organization")
    first_actor = create_user(name: "First owner")
    later_actor = create_user(name: "Later owner")

    first = Agreements.accept!(
      "terms",
      version_id: version.id,
      subject: subject,
      actor: first_actor,
      authority: "organization_owner"
    )
    second = Agreements.accept!(
      "terms",
      version_id: version.id,
      subject: subject,
      actor: later_actor,
      authority: "organization_owner"
    )

    assert_equal first, second
    assert_equal first_actor.to_global_id.to_s, second.actor_key
  end

  test "is immutable after creation" do
    version = create_version
    user = create_user
    acceptance = Agreements.accept!(
      "terms",
      version_id: version.id,
      subject: user,
      actor: user,
      authority: "self"
    )

    assert_raises(ActiveRecord::ReadOnlyRecord) { acceptance.update!(authority: "other") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { acceptance.destroy! }
    assert_raises(ActiveRecord::ReadOnlyRecord) { acceptance.delete }
  end

  test "requires a stable authority label" do
    version = create_version
    user = create_user

    assert_raises(ActiveRecord::RecordInvalid) do
      Agreements.accept!(
        "terms",
        version_id: version.id,
        subject: user,
        actor: user,
        authority: "Organization owner"
      )
    end

    assert_empty Agreements::Acceptance.all
  end

  test "database uniqueness binds one acceptance to each version and subject" do
    version = create_version
    user = create_user
    acceptance = Agreements.accept!(
      "terms",
      version_id: version.id,
      subject: user,
      actor: user,
      authority: "self"
    )

    assert_raises(ActiveRecord::RecordNotUnique) do
      Agreements::Acceptance.insert!(acceptance.attributes.except("id", "created_at", "updated_at"))
    end
  end
end
