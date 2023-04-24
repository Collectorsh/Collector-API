# frozen_string_literal: true

require 'oauth'

class SocialController < ApplicationController
  def create
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end
    ckey = ENV['TWITTER_API_KEY']
    csecret = ENV['TWITTER_API_SECRET']
    consumer = OAuth::Consumer.new(ckey, csecret,
                                   site: 'https://api.twitter.com',
                                   authorize_path: '/oauth/authenticate',
                                   debug_output: false)
    callback_url = "https://api.collector.sh/auth/twitter/callback"
    request_token = consumer.get_request_token(oauth_callback: callback_url)
    token = request_token.token
    token_secret = request_token.secret
    confirmed = request_token.params["oauth_callback_confirmed"]
    if confirmed == "true"
      user.twitter_oauth_token = token
      user.twitter_oauth_secret = token_secret
      user.save!
      render json: { status: 'success', url: "https://api.twitter.com/oauth/authorize?oauth_token=#{token}" }
    else
      render json: { status: 'error' }
    end
  end

  def destroy
    unless (user = User.where("api_key= ?", params[:api_key]).last)
      return render json: { status: 'error',
                            msg: 'API key not found' }
    end
    user.twitter_oauth_token = nil
    user.twitter_oauth_secret = nil
    user.twitter_user_id = nil
    user.twitter_screen_name = nil
    user.save!
    render json: { status: 'success', user: user }
  end
end
