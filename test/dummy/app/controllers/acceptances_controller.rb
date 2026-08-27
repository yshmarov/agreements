# frozen_string_literal: true

class AcceptancesController < ApplicationController
  def show
    render plain: "agreement"
  end

  def create
    user = User.find(params.require(:user_id))
    version = Agreements.current_version("terms")
    Agreements.accept!(
      "terms",
      version_id: params.require(:version_id),
      subject: user,
      actor: user,
      authority: "self",
      acceptance_statement: version.acceptance_statement,
      locale: I18n.locale.to_s
    )
    redirect_to agreement_return_location || "/protected?user_id=#{user.id}", status: :see_other
  end

  def return_path
    session[:return_to_after_agreement] = params[:path] if params.key?(:path)
    render plain: agreement_return_location.to_s
  end
end
