# frozen_string_literal: true

class SessionsController < ApplicationController
  def create
    if params[:oauth_token] && params[:oauth_verifier]
      oauth_token = params["oauth_token"]
      oauth_verifier = params["oauth_verifier"]
      baseUrl = 'https://api.twitter.com/oauth/access_token'

      response = HTTParty.post(baseUrl + "?oauth_token=#{oauth_token}&oauth_verifier=#{oauth_verifier}")

      user_id = response.split("&")[2].split("=")[1]
      screen_name = response.split("&")[3].split("=")[1]
      user = User.find_by(twitter_oauth_token: oauth_token)
      user.twitter_user_id = user_id
      user.twitter_screen_name = screen_name
      user.save!
    end
    redirect_to "https://collector.sh/settings"
  end
end
