# frozen_string_literal: true

class ListingController < ApplicationController
  def usernames
    nfts = params[:nfts]
    nfts.each do |nft|
      nft['listings'].each do |listing|
        if (user = User.where("public_keys LIKE '%#{listing['seller']}%'").last)
          listing['username'] = user.username
        end
      end
    end

    render json: { status: 'success', nfts: nfts }
  end

  def categories
    nfts = params[:nfts]
    sellers = []
    artists = []

    nfts.each do |nft|
      seller_key = nft['listings'][0]['seller']

      if (user = User.where("public_keys LIKE '%#{seller_key}%'").last)
        # add seller username/profile image to each nft
        nft['username'] = user.username
        nft['twitter'] = user.twitter_screen_name
        nft['twitter_profile_image'] = user.twitter_profile_image

        unless sellers.find { |s| s[:public_key] == seller_key }
          count = UserFollowing.where(user_id: user.id).count
          sellers << { name: user.username, public_key: seller_key, followers: count }
        end
      end

      next unless (artist_name = ArtistName.where(public_key: nft['creators'].map { |c| c['address'] }).first)
      next if artists.find { |a| a[:public_key] == artist_name.public_key }

      sales = 0
      sales += MarketplaceSale.where(transaction_type: 'buy', artist_name: artist_name.name).count
      sales += Auction.where(brand_name: artist_name.name).where("number_bids > 0").count

      artists << { name: artist_name.name, public_key: artist_name.public_key, sales: sales }
    end

    render json: { status: 'success', sellers: sellers, artists: artists, listings: nfts }
  end

  def by_user
    user = User.find_by_id(params[:id])
    return render json: { status: 'error', msg: 'User not found' } unless user

    listings = []

    user.marketplace_listings.where(listed: true).where.not(source: "formfunction").each do |l|
      listings << l.attributes
    end

    render json: { status: 'success', listings: listings }
  end

  def mints
    listings = MarketplaceListing.where(listed: true, mint: params[:mints])

    render json: listings
  end

  def collector
    # drop_mints = DropMint.all.pluck(:mint)
    listing = MarketplaceListing.where(source: 'collector',
                                       listed: true) # .where.not(mint: drop_mints)
    listing = listing.sample

    render json: { mint: listing.mint, amount: listing.amount, artist: listing.artist_name&.name,
                   artist_twitter: listing.artist_name&.twitter_profile_image, seller: listing.user&.username, seller_twitter: listing.user&.twitter_profile_image }
  end
end
