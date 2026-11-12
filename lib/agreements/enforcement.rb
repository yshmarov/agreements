# frozen_string_literal: true

require "active_support/concern"

module Agreements
  module Enforcement
    extend ActiveSupport::Concern

    private

    def require_agreement(agreement_key, subject:, location:)
      return unless Agreements.pending_version(agreement_key, subject: subject)

      unless agreement_enforcement_request?
        head :forbidden
        return :forbidden
      end

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
      url_from(session.delete(:return_to_after_agreement))
    end
  end
end
