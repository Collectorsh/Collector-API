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

ActiveRecord::Schema.define(version: 2022_05_12_204400) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "arask_jobs", force: :cascade do |t|
    t.string "job"
    t.datetime "execute_at"
    t.string "interval"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["execute_at"], name: "index_arask_jobs_on_execute_at"
  end

  create_table "artist_names", force: :cascade do |t|
    t.string "public_key"
    t.string "name"
    t.string "collection"
    t.string "twitter"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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
    t.text "public_keys"
    t.boolean "dao", default: false
    t.string "api_key"
    t.boolean "loading", default: false
    t.string "nonce"
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
    t.string "highest_bidder"
    t.integer "number_bids"
    t.string "auction_account"
    t.string "mint"
    t.string "brand_id"
    t.string "brand_name"
    t.string "collection_id"
    t.string "collection_name"
    t.string "image"
    t.string "name"
    t.string "source"
    t.string "metadata_uri"
    t.string "highest_bidder_username"
    t.boolean "cdn_uploaded"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "finalized", default: false
    t.boolean "notified_start", default: false
    t.boolean "notified_end", default: false
    t.boolean "notified_trending", default: false
    t.index ["auction_account"], name: "index_auctions_on_auction_account"
    t.index ["brand_id"], name: "index_auctions_on_brand_id"
    t.index ["brand_name"], name: "index_auctions_on_brand_name"
    t.index ["end_time"], name: "index_auctions_on_end_time"
    t.index ["start_time"], name: "index_auctions_on_start_time"
  end

  create_table "bids", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "auction_id"
    t.bigint "bid"
    t.bigint "end_time"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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

  create_table "follows", force: :cascade do |t|
    t.bigint "user_id"
    t.string "artist"
    t.boolean "notify_start", default: true
    t.boolean "notify_end", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_follows_on_user_id"
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

  create_table "mint_visibilities", force: :cascade do |t|
    t.bigint "user_id"
    t.string "mint_address"
    t.boolean "visible", default: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_mint_visibilities_on_user_id"
  end

  create_table "nfts", force: :cascade do |t|
    t.bigint "artist_id"
    t.text "metadata"
    t.string "mint"
    t.boolean "visible", default: true
    t.integer "order_id"
    t.integer "edition"
    t.string "edition_name"
    t.integer "max_supply"
    t.integer "supply"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["artist_id"], name: "index_nfts_on_artist_id"
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
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "restricted_usernames", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "end_time"
    t.integer "highest_bid"
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
    t.index ["brand_name"], name: "index_sales_on_brand_name"
    t.index ["end_time"], name: "index_sales_on_end_time"
    t.index ["mint"], name: "index_sales_on_mint"
    t.index ["user_id"], name: "index_sales_on_user_id"
  end

  create_table "skeletoncrew_airdrops", force: :cascade do |t|
    t.bigint "artist_id"
    t.string "name"
    t.string "description"
    t.integer "supply"
    t.string "image"
    t.string "artist"
    t.decimal "floor_price", precision: 20, scale: 9
    t.string "floor_mint"
    t.integer "order_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["artist_id"], name: "index_skeletoncrew_airdrops_on_artist_id"
  end

  create_table "token_mints", force: :cascade do |t|
    t.string "mint"
    t.string "owner"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "username"
    t.string "email"
    t.string "public_key"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "default_visibility", default: false
    t.text "public_keys"
    t.string "gallery_view", default: "grid"
    t.string "nonce"
    t.string "api_key"
    t.boolean "border", default: true
    t.boolean "description", default: true
    t.boolean "shadow", default: true
    t.boolean "rounded", default: true
    t.string "twitter_oauth_token"
    t.string "twitter_oauth_secret"
    t.string "twitter_user_id"
    t.string "twitter_screen_name"
    t.datetime "subscription_end"
    t.index ["public_key"], name: "index_users_on_public_key"
    t.index ["username"], name: "index_users_on_username"
  end

  create_table "watchlist_artists", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "watchlist_bids", force: :cascade do |t|
    t.bigint "watchlists_id"
    t.bigint "auctions_id"
    t.bigint "bid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["auctions_id"], name: "index_watchlist_bids_on_auctions_id"
    t.index ["watchlists_id"], name: "index_watchlist_bids_on_watchlists_id"
  end

  create_table "watchlists", force: :cascade do |t|
    t.string "public_key"
    t.string "name"
    t.string "twitter"
    t.string "image"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
