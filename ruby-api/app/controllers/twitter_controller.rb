# frozen_string_literal: true

class TwitterController < ApplicationController
  def profile_image
    twitter_profile_image = TWITTER.user(params[:id]).profile_image_uri.to_s

    render json: twitter_profile_image
  end
end
