# frozen_string_literal: true

class User < ApplicationRecord
  has_many :keys
  has_many :mint_visibilities
  has_many :sales
  has_many :bids
  has_many :follows
  has_many :followings
  has_many :purchases
  has_many :marketplace_sales
  has_many :user_followings
  has_many :marketplace_listings
  has_many :auctions
  has_many :token_mints
  has_many :artist_names, through: :followings
  has_many :mints
  has_one :hub
  has_many :curations, foreign_key: 'curator_id'
  has_many :listed_tokens

  serialize :public_keys, Array
  serialize :allowed_users, Array

  validates :username, allow_nil: true, uniqueness: { case_sensitive: false }

  def public_info
    attributes.except("api_key", "nonce", "twitter_oauth_secret", "twitter_oauth_token")
  end
end
