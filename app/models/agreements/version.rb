# frozen_string_literal: true

require "uri"

module Agreements
  class Version < ApplicationRecord
    SHA256_PATTERN = /\A[0-9a-f]{64}\z/i

    has_many :acceptances,
             class_name: "Agreements::Acceptance",
             foreign_key: :agreement_version_id,
             inverse_of: :agreement_version,
             dependent: :restrict_with_exception

    validates :agreement_key, presence: true, format: { with: /\A[a-z0-9_]+\z/ }, uniqueness: { scope: :version }
    validates :version, :acceptance_statement, presence: true
    validate :documents_are_external_references

    def self.current_for(agreement_key)
      where(agreement_key: agreement_key).order(created_at: :desc, id: :desc).first
    end

    def accepted_by?(subject)
      acceptances.exists?(subject_key: Agreements.identity_key(subject))
    end

    def readonly?
      persisted?
    end

    def delete
      raise ActiveRecord::ReadOnlyRecord, "Agreements::Version is read only" if persisted?

      super
    end

    private

    def documents_are_external_references
      unless documents.is_a?(Array) && documents.any?
        errors.add(:documents, :invalid)
        return
      end

      errors.add(:documents, :invalid) unless documents.all? { |document| valid_document?(document) }
    end

    def valid_document?(document)
      attributes = document.stringify_keys if document.is_a?(Hash)
      attributes && allowed_document_attributes?(attributes) && complete_document_attributes?(attributes)
    end

    def allowed_document_attributes?(attributes)
      attributes.keys.all? { |key| %w[title url sha256].include?(key) }
    end

    def complete_document_attributes?(attributes)
      attributes["title"].present? &&
        external_https_url?(attributes["url"]) &&
        valid_sha256?(attributes["sha256"])
    end

    def external_https_url?(url)
      uri = URI.parse(url.to_s)
      uri.is_a?(URI::HTTPS) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end

    def valid_sha256?(sha256)
      sha256.blank? || sha256.match?(SHA256_PATTERN)
    end
  end
end
