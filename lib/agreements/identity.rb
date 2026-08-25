# frozen_string_literal: true

module Agreements
  module Identity
    module_function

    def key(identity)
      value = identity.is_a?(String) ? identity : global_id_for(identity)
      return value if value.is_a?(String) && !value.strip.empty?

      raise InvalidIdentity, "identity must be a non-empty String or respond to #to_global_id"
    end

    def global_id_for(identity)
      identity.to_global_id.to_s if identity.respond_to?(:to_global_id)
    end
    private_class_method :global_id_for
  end
end
