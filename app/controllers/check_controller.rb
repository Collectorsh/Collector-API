# frozen_string_literal: true

class CheckController < ApplicationController
  def owner
    user = User.where("public_keys like '%#{params[:owner]}%'").first
    token_holder = if user
                     user.token_holder
                   else
                     false
                   end
    render json: { token_holder: token_holder }
  end
end
