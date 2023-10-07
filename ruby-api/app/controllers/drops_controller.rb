# frozen_string_literal: true

class DropsController < ApplicationController
  def index
    drops = Drop.all.select(:id, :name, :description, :url, :creator, :candy_machine, :date, :image, :slug,
                            :highlight).order(id: :desc)
    render json: drops
  end

  def from_name
    drop = Drop.find_by(slug: params[:name])
    render json: drop
  end

  def mints
    drop = Drop.find_by(id: params[:id])
    mints = drop.drop_mints
    listings = MarketplaceListing.where(listed: true, mint: mints.map(&:mint))
    sales = MarketplaceSale.where(mint: mints.map(&:mint))
    drop_mints = []
    mints.each do |m|
      listing = listings.find { |l| l.mint == m.mint }
      result = {}
      result[:mint] = m.mint
      if listing
        result[:listed] = true
        result[:source] = listing.source
        result[:amount] = listing.amount
      end
      if m.artist_name && (artist = ArtistName.find_by(public_key: m.creator_wallet))
        result[:twitter] = artist.twitter if artist.twitter
        result[:twitter_profile_image] = artist.twitter_profile_image if artist.twitter_profile_image
      end
      drop_mints << result
    end
    stats = { sales: sales.count, volume: sales.sum(:amount), listed: listings.count, floor: listings.minimum(:amount) }
    render json: { mints: drop_mints, stats: stats }
  end

  def listing
    listing = MarketplaceListing.where(mint: params[:mint], listed: true).last
    render json: listing
  end

  def listings
    mints = DropMint.where("drop_id <> 5").pluck(:mint)
    listings = MarketplaceListing.select(:mint, :name, :source, :amount, :image).where(listed: true, mint: mints,
                                                                                       source: 'collector').as_json(except: :id)
    render json: listings
  end

  def find_market
    dm = DropMint.find_by(mint: params[:mint])
    return render json: { status: "not_found" } unless dm

    render json: { status: "success", market: dm.drop.slug }
  end
end
