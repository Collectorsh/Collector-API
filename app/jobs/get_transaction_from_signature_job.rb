# frozen_string_literal: true

require 'httparty'
require 'json'

class GetTransactionFromSignatureJob < ApplicationJob
  queue_as :solana

  def perform(signature, marketplace)
    method_wrapper = SolanaRpcRuby::MethodsWrapper.new
    transaction = method_wrapper.get_transaction(
      signature
    )
    trans = transaction.parsed_response['result']

    return unless trans
    return if trans['meta'] && trans['meta']['err'] && !trans['meta']['err'].nil?

    log_messages = trans['meta']['logMessages'].join(' ')

    @type = nil

    if marketplace == 'exchange'
      if log_messages.include?("Instruction: ExecuteBuynowSale")
        @type = "buy"
        update_listing(signature, trans, 'exchange')
      elsif log_messages.include?("Instruction: AcceptOffer")
        @type = "offer"
      elsif log_messages.include?("Instruction: CreateBuynowSale")
        @type = "listing"
        @account = trans['transaction']['message']['accountKeys'][2]
        data = trans['transaction']['message']['instructions'][0]['data']
        data = Btc::Base58.data_from_base58 data
        @amount = data[9..].unpack1('*Q')
      elsif (log_messages.include?("Instruction: MintFixedPriceEdition") || log_messages.include?("Instruction: BuyEditionV2")) && !log_messages.include?("Error")
        @type = "edition"
      elsif log_messages.include?("Instruction: CancelBuynowSale")
        update_listing(signature, trans, 'exchange')
        return
      elsif log_messages.include?("Instruction: EditBuynowSale")
        edit_listing(signature, trans, 'exchange')
        return
      end
    end

    if marketplace == 'formfunction'
      if log_messages.include?("Instruction: CancelV2")
        update_listing(signature, trans,
                       'formfunction') && edited = true
      end

      if log_messages.include?("Instruction: Sell") && log_messages.include?("seller_sale_type = InstantSale")
        keys = trans['transaction']['message']['accountKeys']
        is_sol = keys.include? '3HsusccYUqLfvVfawadnjxQjjAW6GWXYFqpgaKZHvBxw'
        return unless is_sol

        @type = "listing"
        data = if edited
                 trans['transaction']['message']['instructions'][2]['data']
               else
                 trans['transaction']['message']['instructions'][1]['data']
               end
        data = Btc::Base58.data_from_base58 data
        @amount = data[11..].unpack1('*Q')
      elsif log_messages.include?("buyer_sale_type = InstantSale")
        @type = "buy"
        update_listing(signature, trans, 'formfunction')
      elsif log_messages.include?("Instruction: BuyEdition")
        @type = "edition"
      elsif log_messages.include?("buyer_sale_type = Offer")
        @type = "offer"
      end
    end

    return unless @type
    return if trans['meta']['postTokenBalances'][0].nil?

    time = trans['blockTime']

    trans['meta']['postTokenBalances'].each do |account|
      next unless account['uiTokenAmount']['uiAmountString'] == '1' && account['uiTokenAmount']['decimals'].zero?

      @owner = account['owner']
      @mint = account['mint']
      break
    end
    trans['meta']['preTokenBalances'].each do |account|
      next unless account['uiTokenAmount']['uiAmountString'] == '1' && account['uiTokenAmount']['decimals'].zero?

      @seller = account['owner']
      break
    end

    case @type
    when "buy", "edition"
      amount = trans['meta']['preBalances'][0] - trans['meta']['postBalances'][0]
    when "offer"
      case marketplace
      when 'exchange'
        amount = trans['meta']['postBalances'][0] - trans['meta']['preBalances'][0]
        fee = trans['meta']['postBalances'][2] - trans['meta']['preBalances'][2]
        royalty = trans['meta']['postBalances'][4] - trans['meta']['preBalances'][4]
        amount = amount + fee + royalty
      when 'formfunction'
        amount = trans['meta']['postBalances'][0] - trans['meta']['preBalances'][0]
        fee = trans['meta']['postBalances'][2] - trans['meta']['preBalances'][2]
        royalty = trans['meta']['postBalances'][6] - trans['meta']['preBalances'][6]
        amount = amount + fee + royalty
      end
    when "listing"
      amount = @amount
    end

    return if amount.to_i.negative?

    if @type == 'buy' || @type == 'offer' || @type == 'edition'
      AddMarketplaceSaleJob.perform_later(@type, amount, @mint, @owner, time, marketplace, @seller,
                                          signature)
    end
    if @type == 'listing'
      AddMarketplaceListingJob.perform_later(@type, amount, @mint, @owner, time, marketplace, @seller,
                                             signature, @account)
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end

  def update_listing(signature, trans, source)
    mint = trans['meta']['postTokenBalances'][0]['mint']
    return if MarketplaceListing.find_by_last_signature(signature)

    MarketplaceListing.where(mint: mint, source: source, listed: true).each do |listing|
      listing.listed = false
      listing.last_signature = signature

      unless listing.artist_name_id
        metadata = Metadata.find_pda(mint)
        creator = metadata[:creators][0]
        artist = ArtistName.where(public_key: creator).first_or_create
        listing.artist_name_id = artist.id
      end

      listing.save!
    end
  end

  def edit_listing(signature, trans, source)
    account = trans['transaction']['message']['accountKeys'][1]
    return if MarketplaceListing.find_by_last_signature(signature)

    MarketplaceListing.where(account: account, source: source, listed: true).each do |listing|
      data = trans['transaction']['message']['instructions'][0]['data']
      data = Btc::Base58.data_from_base58 data
      amount = data[8..].unpack1('*Q')

      listing.amount = amount
      listing.last_signature = signature
      listing.save!
    end
  end
end
