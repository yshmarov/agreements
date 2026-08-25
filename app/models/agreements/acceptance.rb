# frozen_string_literal: true

module Agreements
  class Acceptance < ApplicationRecord
    belongs_to :agreement_version,
               class_name: "Agreements::Version",
               inverse_of: :acceptances

    validates :subject_key, :actor_key, :authority, :accepted_at, presence: true
    validates :authority, format: { with: /\A[a-z0-9_]+\z/ }

    def readonly?
      persisted?
    end

    def delete
      raise ActiveRecord::ReadOnlyRecord, "Agreements::Acceptance is read only" if persisted?

      super
    end
  end
end
