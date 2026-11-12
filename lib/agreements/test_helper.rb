# frozen_string_literal: true

module Agreements
  module TestHelper
    def accept_agreement(agreement_key, subject:, actor: subject, authority: "self", locale: "en")
      version = Agreements.current_version(agreement_key)
      raise ArgumentError, "no current #{agreement_key} version; insert one in your test setup" unless version

      Agreements.accept!(
        agreement_key,
        version_id: version.id,
        subject: subject,
        actor: actor,
        authority: authority,
        acceptance_statement: version.acceptance_statement,
        locale: locale
      )
    end
  end
end
