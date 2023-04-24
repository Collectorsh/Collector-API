# frozen_string_literal: true

class SalesController < ApplicationController
  def recent
    sales = []

    Sale.select("users.parent_id, users.username, sales.*").joins(:user).order(end_time: :desc).limit(6).each do |sale|
      if sale.parent_id
        user = User.find_by_id(sale.parent_id)
        sale.username = user.username
      end
      sales << sale
    end

    render json: sales
  end

  def by_mint
    results = []

    MarketplaceSale.select(:buyer, :seller, :amount, :source, :timestamp).where(mint: params[:mint]).each do |s|
      results << { buyer: s.buyer, seller: s.seller, amount: s.amount, marketplace: s.source,
                   time: s.timestamp }
    end
    Auction.where(mint: params[:mint], finalized: true).where("end_time < '#{Time.now.to_i}'").each do |a|
      results << { buyer: a.highest_bidder, seller: a.seller, amount: a.highest_bid, marketplace: a.source,
                   time: a.end_time }
    end

    render json: results
  end
end
