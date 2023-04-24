# frozen_string_literal: true

class UpdateArtistTwitterJob < ApplicationJob
  queue_as :default

  def perform
    ArtistName.where("twitter IS NOT NULL AND source != 'holaplex'").order("twitter_image_updated_at ASC NULLS FIRST").limit(300).each do |artist|
      twitter_profile_image = TWITTER.user(artist.twitter[1..]).profile_image_uri.to_s
      artist.twitter_profile_image = twitter_profile_image
      artist.twitter_image_updated_at = Time.now
      artist.save!
    rescue Twitter::Error::NotFound, Twitter::Error::Forbidden
      artist.twitter = nil
      artist.twitter_profile_image = nil
      artist.twitter_image_updated_at = Time.now
      artist.save!
    rescue StandardError => e
      Bugsnag.notify(e)
    end

    ArtistName.where("twitter IS NULL AND source != 'holaplex' AND created_at > '#{Time.now - 1.day}'").each do |artist|
      twitter = get_artist_twitter_exchange(artist.collection) if artist.source == 'exchange'
      # twitter = get_artist_twitter_formfunction(artist.name) if artist.source == 'formfunction'
      twitter = get_artist_twitter_holaplex(artist.public_key) if artist.source == 'holaplex'

      artist.update_attribute(:twitter, twitter) if twitter
    rescue StandardError => e
      Bugsnag.notify(e)
    end
  end
end
