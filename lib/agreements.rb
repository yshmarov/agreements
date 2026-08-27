# frozen_string_literal: true

require "agreements/version"
require "agreements/errors"
require "agreements/identity"
require "agreements/recorder"
require "agreements/enforcement"
require "agreements/engine"

module Agreements
  def self.table_name_prefix
    "agreements_"
  end

  class << self
    def current_version(agreement_key)
      Version.current_for(agreement_key)
    end

    def pending_version(agreement_key, subject:)
      current_version(agreement_key).then do |version|
        version unless version.nil? || version.accepted_by?(subject)
      end
    end

    # Explicit keywords keep this evidence boundary distinct from browser params.
    # rubocop:disable-next Metrics/ParameterLists
    def accept!(agreement_key, version_id:, subject:, actor:, authority:, acceptance_statement:, locale:)
      version = current_version(agreement_key)
      raise VersionNotCurrent, version unless version&.id.to_s == version_id.to_s

      Recorder.call(
        agreement_version: version,
        evidence: {
          subject: subject,
          actor: actor,
          authority: authority,
          acceptance_statement: acceptance_statement,
          locale: locale
        }
      )
    end

    def identity_key(identity)
      Identity.key(identity)
    end
  end

  private_constant :Recorder
end
