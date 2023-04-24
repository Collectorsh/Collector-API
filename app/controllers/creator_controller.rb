# frozen_string_literal: true

class CreatorController < ApplicationController
  def details
    tokens = params[:tokens]
    creators = tokens.collect { |t| t['creator'] }
    artists = ArtistName.where(public_key: creators).where("name IS NOT NULL")

    render json: artists
  end
end
