# frozen_string_literal: true

class GetMintOwnerJob < ApplicationJob
  queue_as :default

  def perform
    update_token_mints
    fetch_mint_owner
    update_token_holders
  rescue StandardError => e
    Bugsnag.notify(e)
  end

  def update_token_holders
    owners = TokenMint.pluck(:owner)
    # Check existing token_holder and revoke if they aren't in the owners array
    User.where(token_holder: true).each do |u|
      next if u.id == 3

      u.update_attribute :token_holder, false if (owners & u.public_keys).empty?
    end
    owners.each do |owner|
      user = User.where("public_keys LIKE '%#{owner}%'").first
      m = TokenMint.find_by(owner: owner)

      if user
        user.update_attribute :token_holder, true unless user.token_holder
        m.update_attribute :user_id, user.id
      else
        m.update_attribute :user_id, nil
      end
    end
  end

  def update_token_mints
    system("/home/richard/.cargo/bin/metaboss -T 300 snapshot mints -c AHdb8jSpvqkJSYjnMT2TaR7zjV3qT3RkzD1QaeBn5odA --v2 -r https://blissful-lingering-forest.solana-mainnet.quiknode.pro")
    file = File.open("AHdb8jSpvqkJSYjnMT2TaR7zjV3qT3RkzD1QaeBn5odA_mint_accounts.json")
    data = file.read
    data = JSON.parse data
    data.each do |mint|
      TokenMint.where(mint: mint).first_or_create
    end
  rescue StandardError => e
    Bugsnag.notify(e)
  end

  def fetch_mint_owner
    method_wrapper = SolanaRpcRuby::MethodsWrapper.new

    TokenMint.all.each do |token|
      # find largest account
      response = method_wrapper.get_token_largest_accounts(
        token.mint
      )
      results = response.parsed_response['result']
      address = results['value'][0]['address']

      # find account owner
      response = method_wrapper.get_account_info(
        address,
        encoding: 'jsonParsed'
      )
      results = response.parsed_response['result']
      owner = results['value']['data']['parsed']['info']['owner']

      token.update_attribute :owner, owner
    end
  end
end
