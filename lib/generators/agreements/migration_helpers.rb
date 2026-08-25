# frozen_string_literal: true

module Agreements
  module Generators
    module MigrationHelpers
      private

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end

      def primary_key_type_option
        type = primary_key_type
        type ? ", id: :#{type}" : ""
      end

      def reference_type_option
        type = primary_key_type
        type ? ", type: :#{type}" : ""
      end

      def primary_key_type
        config = Rails.configuration.generators
        config.options[config.orm][:primary_key_type]
      end
    end
  end
end
