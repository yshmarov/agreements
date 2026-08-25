# frozen_string_literal: true

module Agreements
  class Error < StandardError; end

  class InvalidIdentity < Error; end

  class VersionNotCurrent < Error
    attr_reader :current_version

    def initialize(current_version)
      @current_version = current_version
      super("The submitted agreement version is not current")
    end
  end
end
