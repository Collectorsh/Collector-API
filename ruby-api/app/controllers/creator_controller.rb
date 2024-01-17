# frozen_string_literal: true

class CreatorController < ApplicationController
  def details
    tokens = params[:tokens]
    creators = tokens.collect { |t| t['artist_address'] }
    artists = ArtistName.where(public_key: creators).where("name IS NOT NULL")

    artistUsers = Users.where(public_key: creators).where("name IS NOT NULL")

    render json: artists
  rescue => e
    puts "error: #{e.message}"
  end
end
