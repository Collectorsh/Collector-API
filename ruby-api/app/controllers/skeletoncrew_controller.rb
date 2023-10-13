# frozen_string_literal: true

class SkeletoncrewController < ApplicationController
  def airdrops
    render json: Airdrop.all.joins(:skele_artist).select('skele_artists.name as artist_name, airdrops.name, airdrops.description,
      airdrops.supply, airdrops.image, airdrops.floor_price, airdrops.floor_mint, airdrops.order_id').to_json
  end

  def artist
    artist = SkeleArtist.find_by_name(params[:name])
    render json: { artist: artist, airdrops: artist.airdrops }.to_json
  end
end
