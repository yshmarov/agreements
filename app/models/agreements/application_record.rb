# frozen_string_literal: true

module Agreements
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
