# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_04_20_191900) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "airdrops", id: :bigint, default: -> { "nextval('skeletoncrew_airdrops_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "supply"
    t.string "image"
    t.decimal "floor_price", precision: 20, scale: 9
    t.string "floor_mint"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "order_id"
    t.integer "skele_artist_id"
  end

  create_table "artist_names", force: :cascade do |t|
    t.string "public_key"
    t.string "name"
    t.string "collection"
    t.string "source"
    t.string "twitter"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "twitter_profile_image"
    t.datetime "twitter_image_updated_at", precision: 6
    t.index ["collection"], name: "index_artist_names_on_collection"
    t.index ["name"], name: "index_artist_names_on_name"
    t.index ["public_key"], name: "index_artist_names_on_public_key"
    t.index ["source"], name: "index_artist_names_on_source"
  end

  create_table "artists", force: :cascade do |t|
    t.string "name"
    t.string "twitter"
    t.text "bio"
    t.text "tags"
    t.string "exchange"
    t.string "holaplex"
    t.string "formfunction"
    t.text "images"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "auctions", force: :cascade do |t|
    t.bigint "start_time"
    t.bigint "end_time"
    t.bigint "reserve"
    t.bigint "min_increment"
    t.bigint "ending_phase"
    t.bigint "extension"
    t.bigint "highest_bid"
    t.integer "number_bids", default: 0
    t.string "auction_account"
    t.string "mint"
    t.string "brand_id"
    t.string "brand_name"
    t.string "collection_id"
    t.string "collection_name"
    t.string "image"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "finalized", default: false
    t.string "highest_bidder"
    t.string "source"
    t.string "metadata_uri"
    t.string "highest_bidder_username"
    t.boolean "cdn_uploaded", default: false
    t.boolean "secondary", default: false
    t.boolean "notified_start", default: false
    t.boolean "notified_end", default: false
    t.boolean "notified_trending", default: false
    t.boolean "notified_new_artist", default: false
    t.string "seller"
    t.bigint "user_id"
    t.integer "artist_name_id"
    t.index ["auction_account"], name: "index_auctions_on_auction_account"
    t.index ["brand_id"], name: "index_auctions_on_brand_id"
    t.index ["brand_name"], name: "index_auctions_on_brand_name"
    t.index ["collection_name"], name: "index_auctions_on_collection_name"
    t.index ["end_time"], name: "index_auctions_on_end_time"
    t.index ["finalized"], name: "index_auctions_on_finalized"
    t.index ["start_time"], name: "index_auctions_on_start_time"
  end

  create_table "bids", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "auction_id"
    t.bigint "bid"
    t.bigint "end_time"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "outbid", default: false
    t.index ["auction_id"], name: "index_bids_on_auction_id"
    t.index ["user_id"], name: "index_bids_on_user_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "discord_bids", force: :cascade do |t|
    t.bigint "auction_id"
    t.bigint "discord_notification_id"
    t.bigint "bid"
    t.bigint "end_time"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["auction_id"], name: "index_discord_bids_on_auction_id"
    t.index ["discord_notification_id"], name: "index_discord_bids_on_discord_notification_id"
  end

  create_table "discord_notifications", force: :cascade do |t|
    t.string "name"
    t.string "collection_name"
    t.text "creator"
    t.string "channel_id"
    t.boolean "listings", default: true
    t.boolean "sales", default: true
    t.boolean "auctions_end", default: true
    t.boolean "bids", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "auctions_start", default: false
    t.text "artists"
    t.string "discord_name"
  end

  create_table "drop_mints", id: :bigint, default: -> { "nextval('drops_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "artist_name"
    t.string "name"
    t.string "description"
    t.string "mint"
    t.string "image"
    t.string "edition"
    t.string "drop"
    t.string "candymachine"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "creator_wallet"
    t.boolean "updated_creator", default: false
    t.string "uri"
    t.integer "drop_id"
    t.boolean "updated_authority", default: false
  end

  create_table "drops", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "creator"
    t.string "url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "candy_machine"
    t.string "slug"
    t.boolean "closed", default: false
    t.boolean "market", default: false
    t.string "date"
    t.string "image"
    t.boolean "highlight", default: false
    t.string "collection_address"
    t.string "required_collection"
    t.boolean "active", default: true
    t.bigint "lamports"
  end

  create_table "followings", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "artist_name_id"
    t.boolean "notify_start", default: true
    t.boolean "notify_end", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "notify_listing", default: true
    t.boolean "notify_edition", default: true
    t.index ["artist_name_id"], name: "index_followings_on_artist_name_id"
    t.index ["user_id"], name: "index_followings_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "user_id"
    t.string "artist"
    t.boolean "notify_start", default: true
    t.boolean "notify_end", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "notify_listing", default: true
    t.boolean "notify_edition", default: true
    t.index ["artist"], name: "index_follows_on_artist_id"
    t.index ["user_id"], name: "index_follows_on_user_id"
  end

  create_table "hubs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name"
    t.string "description"
    t.string "auction_house"
    t.string "basis_points"
    t.string "wallet"
    t.index ["user_id"], name: "index_hubs_on_user_id"
  end

  create_table "keys", force: :cascade do |t|
    t.bigint "user_id"
    t.string "api_key"
    t.string "nonce"
    t.boolean "active", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_keys_on_user_id"
  end

  create_table "listings", force: :cascade do |t|
    t.string "mint"
    t.boolean "is_listed"
    t.datetime "last_listed"
    t.string "listed_by"
    t.bigint "last_sale_price"
    t.bigint "last_listed_price"
    t.string "image"
    t.string "name"
    t.string "description"
    t.string "title"
    t.boolean "cdn_uploaded", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_listings_on_name"
  end

  create_table "marketplace_listings", force: :cascade do |t|
    t.bigint "timestamp"
    t.integer "user_id"
    t.string "artist_name"
    t.string "name"
    t.string "source"
    t.string "mint"
    t.string "twitter"
    t.bigint "amount"
    t.string "image"
    t.string "buyer"
    t.string "seller"
    t.string "signature"
    t.string "creator"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "listed", default: true
    t.string "last_signature"
    t.string "twitter_profile_image"
    t.string "collection"
    t.string "account"
    t.bigint "estimate"
    t.boolean "notified", default: false
    t.boolean "estimate_run", default: false
    t.integer "artist_name_id"
    t.index ["artist_name"], name: "index_marketplace_listings_on_artist_name"
    t.index ["mint"], name: "index_marketplace_listings_on_mint"
    t.index ["timestamp"], name: "index_marketplace_listings_on_timestamp"
    t.index ["user_id"], name: "index_marketplace_listings_on_user_id"
  end

  create_table "marketplace_sales", force: :cascade do |t|
    t.bigint "timestamp"
    t.string "artist_name"
    t.string "name"
    t.string "source"
    t.string "mint"
    t.string "twitter"
    t.bigint "amount"
    t.string "image"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "buyer"
    t.string "seller"
    t.string "signature"
    t.integer "user_id"
    t.string "creator"
    t.string "transaction_type"
    t.string "subdomain"
    t.integer "artist_name_id"
    t.index ["artist_name"], name: "index_marketplace_sales_on_artist_name"
    t.index ["mint"], name: "index_marketplace_sales_on_mint"
    t.index ["timestamp"], name: "index_marketplace_sales_on_timestamp"
    t.index ["user_id"], name: "index_marketplace_sales_on_user_id"
  end

  create_table "mint_visibilities", force: :cascade do |t|
    t.bigint "user_id"
    t.string "mint_address"
    t.boolean "visible", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "order_id"
    t.boolean "cdn_uploaded", default: false
    t.boolean "accept_offers", default: false
    t.string "image"
    t.bigint "estimate"
    t.boolean "estimate_run", default: false
    t.datetime "estimate_run_at", precision: 6
    t.integer "span", default: 1
    t.index ["user_id"], name: "index_mint_visibilities_on_user_id"
  end

  create_table "mints", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name"
    t.string "description"
    t.string "image"
    t.string "uri"
    t.string "symbol"
    t.string "mint"
    t.string "address"
    t.string "collection"
    t.string "edition_type"
    t.string "supply"
    t.string "max_supply"
    t.string "print"
    t.index ["user_id"], name: "index_mints_on_user_id"
  end

  create_table "product_collections", force: :cascade do |t|
    t.string "name"
    t.string "image"
    t.string "uuid"
    t.string "description"
    t.string "wallet"
    t.string "email"
  end

  create_table "product_mint_lists", force: :cascade do |t|
    t.string "name"
    t.string "mint"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "price_usd_cents"
    t.boolean "gated", default: false
    t.string "mint_list_name"
    t.integer "holder_discount"
    t.boolean "active", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "images"
    t.bigint "lamports"
    t.string "uuid"
    t.text "sizes"
    t.integer "product_collection_id"
    t.integer "supply"
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "user_id"
    t.string "public_key"
    t.string "signature"
    t.bigint "lamports"
    t.integer "months"
    t.boolean "verified", default: false
    t.text "result"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "order"
    t.text "address"
    t.string "order_number"
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "restricted_usernames", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "rotating_drops", force: :cascade do |t|
    t.string "artist_name"
    t.string "name"
    t.text "schedule"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "end_time"
    t.bigint "highest_bid"
    t.integer "number_of_bids"
    t.string "mint"
    t.string "name"
    t.string "brand_name"
    t.string "collection_name"
    t.string "image"
    t.string "source"
    t.string "metadata_uri"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "highest_bidder_username"
    t.index ["brand_name"], name: "index_sales_on_brand_name"
    t.index ["end_time"], name: "index_sales_on_end_time"
    t.index ["mint"], name: "index_sales_on_mint"
    t.index ["user_id"], name: "index_sales_on_user_id"
  end

  create_table "skele_artists", force: :cascade do |t|
    t.string "name"
    t.string "bio"
    t.string "twitter_name"
    t.integer "twitter_id"
    t.string "twitter_image"
    t.string "exchange"
    t.string "holaplex"
    t.string "website"
    t.text "other_work"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "token_mints", force: :cascade do |t|
    t.string "mint"
    t.string "owner"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_id"
  end

  create_table "uploaded_images", force: :cascade do |t|
    t.string "mint"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "success", default: false
    t.integer "retries", default: 0
    t.index ["mint"], name: "index_uploaded_images_on_mint"
  end

  create_table "user_followings", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "following_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_user_followings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.string "public_key"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "default_visibility", default: true
    t.text "public_keys"
    t.string "gallery_view", default: "grid"
    t.string "nonce"
    t.string "api_key"
    t.boolean "border", default: true
    t.boolean "description", default: true
    t.boolean "shadow", default: true
    t.boolean "rounded", default: false
    t.boolean "names", default: true
    t.boolean "pro", default: false
    t.string "twitter_oauth_token"
    t.string "twitter_oauth_secret"
    t.string "twitter_user_id"
    t.string "twitter_screen_name"
    t.boolean "token_holder", default: false
    t.boolean "estimated_value", default: false
    t.boolean "notify_trending", default: false
    t.datetime "subscription_end"
    t.boolean "notify_outbid", default: false
    t.integer "parent_id"
    t.boolean "show_artist_name", default: true
    t.boolean "notify_new_artist", default: false
    t.boolean "watchlist_to_dm", default: false
    t.boolean "notify_twitter", default: false
    t.boolean "notify_email", default: false
    t.string "twitter_profile_image"
    t.string "profile_image"
    t.integer "views", default: 0
    t.boolean "dao", default: false
    t.datetime "twitter_image_updated_at", precision: 6
    t.integer "columns", default: 3
    t.string "name"
    t.string "bio"
    t.boolean "artist", default: false
    t.boolean "curator", default: false
    t.text "allowed_users"
    t.index ["public_key"], name: "index_users_on_public_key"
    t.index ["username"], name: "index_users_on_username"
  end

  create_table "watchlist_artists", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "watchlist_bids", force: :cascade do |t|
    t.bigint "watchlist_id"
    t.bigint "auction_id"
    t.bigint "bid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "end_time"
    t.index ["auction_id"], name: "index_watchlist_bids_on_auctions_id"
    t.index ["watchlist_id"], name: "index_watchlist_bids_on_watchlists_id"
  end

  create_table "watchlists", force: :cascade do |t|
    t.string "public_key"
    t.string "name"
    t.string "twitter"
    t.string "image"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "twitter_screen_name"
  end

  create_table "zmb_mints", force: :cascade do |t|
    t.string "name"
    t.string "mint"
    t.string "uri"
    t.string "holder"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
