# frozen_string_literal: true

class CreatorController < ApplicationController
  def details
    tokens = params[:tokens]
    creators = tokens.collect { |t| t['artist_address'] }
    artists = ArtistName.includes(:artist).where(public_key: creators).order(updated_at: :asc) 

    artist_map = {}
    to_override = []

    #ordered as asc so that most recent will override previous names
    artists.each do |a|
      if a.artist_id 
        to_override.push({ public_key: a.public_key, name: a.artist.username })
      elsif a.name 
        artist_map[a.public_key] = a.name 
      end
    end

    #override with usernames from collector
    to_override.each do |a|
      artist_map[a[:public_key]] = a[:name]
    end

    render json: artist_map
  rescue => e
    puts "error: #{e.message}"
  end
end
