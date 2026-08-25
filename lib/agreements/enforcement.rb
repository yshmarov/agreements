# frozen_string_literal: true

require "active_support/concern"

module Agreements
  module Enforcement
    extend ActiveSupport::Concern

    private

    def require_agreement(agreement_key, subject:, location:)
      return unless agreement_enforcement_request?
      return unless Agreements.pending_version(agreement_key, subject: subject)

      remember_agreement_return_location
      redirect_to location, status: :see_other
      :redirected
    end

    def agreement_enforcement_request?
      request.format.html? || request.format == Mime[:turbo_stream]
    end

    def remember_agreement_return_location
      if request.get? || request.head?
        session[:return_to_after_agreement] = request.fullpath
      else
        session.delete(:return_to_after_agreement)
      end
    end

    def agreement_return_location
      path = session.delete(:return_to_after_agreement)
      path if path&.start_with?("/") && !path.start_with?("//")
    end
  end
end
