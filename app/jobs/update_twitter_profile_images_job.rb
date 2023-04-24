# frozen_string_literal: true

class UpdateTwitterProfileImagesJob < ApplicationJob
  queue_as :twitter

  def perform
    User.where("twitter_screen_name IS NOT NULL").order("twitter_image_updated_at ASC NULLS FIRST").limit(300).each do |u|
      twitter_profile_image = TWITTER.user(u.twitter_screen_name).profile_image_uri.to_s
      u.twitter_profile_image = twitter_profile_image
      u.twitter_image_updated_at = Time.now
      u.save!
    rescue Twitter::Error::NotFound, Twitter::Error::Forbidden
      u.twitter_screen_name = nil
      u.twitter_oauth_token = nil
      u.twitter_oauth_secret = nil
      u.twitter_user_id = nil
      u.twitter_profile_image = nil
      u.twitter_image_updated_at = Time.now
      u.save!
    rescue StandardError => e
      Bugsnag.notify(e)
    end
  end
end
