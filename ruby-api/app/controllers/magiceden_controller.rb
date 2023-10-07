# frozen_string_literal: true

class MagicedenController < ApplicationController
  def escrows
    response = HTTParty.get("https://api-mainnet.magiceden.io/rpc/getNFTsByEscrowOwner/#{params[:public_key]}")
    render json: response.body
  rescue StandardError => e
    Rails.logger.error e.message
  end

  def biddings
    q = "{\"$match\":{\"initializerDepositTokenMintAccount\":{\"$in\":#{params[:mints].split(',')}}},\"$sort\":{\"createdAt\":-1}}"
    q = CGI.escape q
    url = "https://api-mainnet.magiceden.io/rpc/getBiddingsByQuery?q=#{q}"
    response = HTTParty.get(url)
    render json: response.body
  rescue StandardError => e
    Rails.logger.error e.message
  end
end
