# frozen_string_literal: true

class ProtectedController < ApplicationController
  before_action :require_terms

  def index
    render plain: "protected"
  end

  def create
    render plain: "created"
  end

  private

  def require_terms
    require_agreement("terms", subject: User.find(params.require(:user_id)), location: "/agreement")
  end
end
