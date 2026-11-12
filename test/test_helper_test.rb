# frozen_string_literal: true

require "test_helper"

class TestHelperTest < ActiveSupport::TestCase
  include Agreements::TestHelper

  test "accepts the current version for a subject" do
    user = create_user
    version = create_version

    acceptance = accept_agreement("terms", subject: user)

    assert_equal version, acceptance.agreement_version
    assert_equal version.acceptance_statement, acceptance.acceptance_statement
    assert_nil Agreements.pending_version("terms", subject: user)
  end

  test "records a separate actor and authority" do
    owner = create_user
    organization = "gid://dummy/Organization/1"
    create_version(agreement_key: "dpa")

    acceptance = accept_agreement("dpa", subject: organization, actor: owner, authority: "organization_owner")

    assert_equal organization, acceptance.subject_key
    assert_equal owner.to_global_id.to_s, acceptance.actor_key
  end

  test "explains a missing version" do
    error = assert_raises(ArgumentError) { accept_agreement("terms", subject: create_user) }

    assert_match "no current terms version", error.message
  end
end
