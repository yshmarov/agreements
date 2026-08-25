# frozen_string_literal: true

module Agreements
  class HostController < ApplicationController
    def show
      redirect_to agreement_path
    end
  end
end
