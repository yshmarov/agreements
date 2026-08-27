# frozen_string_literal: true

module Agreements
  class Recorder
    def self.call(agreement_version:, evidence:)
      Acceptance.create_or_find_by!(
        agreement_version: agreement_version,
        subject_key: Agreements.identity_key(evidence.fetch(:subject))
      ) do |acceptance|
        acceptance.actor_key = Agreements.identity_key(evidence.fetch(:actor))
        acceptance.authority = evidence.fetch(:authority)
        acceptance.acceptance_statement = evidence.fetch(:acceptance_statement)
        acceptance.locale = evidence.fetch(:locale)
        acceptance.accepted_at = Time.current
      end
    end
  end
end
