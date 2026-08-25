# frozen_string_literal: true

module Agreements
  class Recorder
    def self.call(agreement_version:, subject:, actor:, authority:)
      Acceptance.create_or_find_by!(
        agreement_version: agreement_version,
        subject_key: Agreements.identity_key(subject)
      ) do |acceptance|
        acceptance.actor_key = Agreements.identity_key(actor)
        acceptance.authority = authority
        acceptance.accepted_at = Time.current
      end
    end
  end
end
