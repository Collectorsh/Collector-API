Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  post '/getusername', to: 'user#getusername'
  post '/createusername', to: 'user#create_or_update_username'
  post '/getpublickeys_fromusername', to: 'user#getpublickeys_fromusername'
  post '/getpublickeys', to: 'user#getpublickeys'
  post '/deletewallet', to: 'user#delete_wallet'
  post '/add_wallet', to: 'user#add_wallet'
  post '/add_wallet_with_secret', to: 'user#add_wallet_with_secret'
  post '/request_nonce', to: 'user#request_nonce'

  post '/request_api_key', to: 'api_key#request_api_key'
  post '/create_api_key', to: 'api_key#create_api_key'

  post '/metadata', to: 'metadata#metadata'
  post '/editiondata', to: 'edition#editiondata'

  post '/batch_metadata', to: 'metadata#batch_metadata'
  post '/batch_editiondata', to: 'edition#batch_editiondata'

  post '/visibility_and_order', to: 'visibility#set_visibility_and_order'
  post '/get_visibility_and_order', to: 'visibility#visibility_and_order'

  post '/default_visibility', to: 'user#default_visibility'
  post '/gallery_view', to: 'user#gallery_view'

  match 'airdrops', to: 'skeletoncrew#airdrops', via: %i[get]
  match 'artist', to: 'skeletoncrew#artist', via: %i[post]

  scope :magiceden do
    get '/escrows', to: 'magiceden#escrows'
    get '/biddings', to: 'magiceden#biddings'
  end

  scope :check do
    post '/owner', to: 'check#owner'
  end

  scope :user do
    post '/from_api_key', to: 'user#from_api_key'
    post '/from_username', to: 'user#from_username'
    post '/save', to: 'user#save'
    post '/bids', to: 'user#bids'
    post '/follow_unfollow', to: 'user#follow_unfollow'
    post '/follows', to: 'user#follows'
    post '/save_mints', to: 'user#save_mints'
    post '/mints', to: 'user#mints'
    post '/update_bio', to: 'user#update_bio'
    post '/update_profile_image', to: 'user#update_profile_image'
    post '/update_banner_image', to: 'user#update_banner_image'
    post '/update_socials', to: 'user#update_socials'
    post '/get_curator_by_username', to: 'user#get_curator_by_username'
    post '/get_user_by_address', to: 'user#get_user_by_address'
    post '/verify', to: 'user#verify'
    post '/save_curations_order', to: 'user#save_curations_order'
    post '/update_display_name', to: 'user#update_display_name'
  end

  scope :following do
    post '/id', to: 'following#from_id'
    post '/get', to: 'following#get'
    post '/update', to: 'following#update'
    post '/search', to: 'following#search'
    post '/auctions', to: 'following#auctions'
    post '/listings', to: 'following#listings'
    post '/unfollow', to: 'following#unfollow'
    post '/follow', to: 'following#follow'
  end

  scope :signature do
    post '/listings', to: 'signature#listings'
  end

  scope :sales do
    post '/recent', to: 'sales#recent'
    post '/by_mint', to: 'sales#by_mint'
  end

  scope :watchlist do
    post '/bids', to: 'watchlist#bids'
    post '/collectors', to: 'watchlist#collectors'
    post '/artists', to: 'watchlist#artists'
  end

  scope :estimate do
    post '/price', to: 'estimate#price'
  end

  scope :purchase do
    post '/verify', to: 'purchase#verify'
  end

  scope :creator do
    post '/details', to: 'creator#details'
  end

  scope :images do
    post '/upload', to: 'images#upload'
    post '/upload_with_mints', to: 'images#upload_with_mints'
    post '/upload_with_tokens', to: 'images#upload_with_tokens'
    post '/upload_single_token', to: 'images#upload_single_token'
    post '/upload_image_buffer', to: 'images#upload_image_buffer'
    post '/upload_video', to: 'images#upload_video'
  end

  scope :listing do
    post '/usernames', to: 'listing#usernames'
    post '/categories', to: 'listing#categories'
    post '/by_user', to: 'listing#by_user'
    post '/mints', to: 'listing#mints'
    post '/collector', to: 'listing#collector'
  end

  scope :feed do
    post '/get', to: 'feed#get'
    post '/following', to: 'feed#following'
    post '/listings', to: 'feed#listings'
  end

  scope :featured do
    post '/wins', to: 'featured#wins'
    post '/followers', to: 'featured#followers'
    post '/artists', to: 'featured#artists'
    post '/marketplace_stats', to: 'featured#marketplace_stats'
  end

  scope :auctions do
    post '/get', to: 'auctions#get'
    post '/live', to: 'auctions#live'
  end

  scope :galleries do
    post '/get', to: 'galleries#get'
    post '/new', to: 'galleries#new'
    post '/popular', to: 'galleries#popular'
    post '/daos', to: 'galleries#daos'
    post '/sample', to: 'galleries#sample'
    post '/curated', to: 'galleries#curated'
    post '/get_all', to: 'galleries#get_all'

  end

  scope :products do
    post '/get', to: 'products#get'
    post '/get_product', to: 'products#product'
    post '/collections', to: 'products#collections'
    post '/get_collection', to: 'products#collection'
    post '/products', to: 'products#products'
  end

  scope :drops do
    get '/', to: 'drops#index'
    post '/from_name', to: 'drops#from_name'
    post '/mints', to: 'drops#mints'
    post '/listing', to: 'drops#listing'
    post '/listings', to: 'drops#listings'
    post '/find_market', to: 'drops#find_market'
  end

  scope :hub do
    post '/fetch_config', to: 'hub#fetch_config'
    post '/save_config', to: 'hub#save_config'
    post '/fetch_all_users', to: 'hub#fetch_all_users'
    post '/add_user', to: 'hub#add_user'
    post '/remove_user', to: 'hub#remove_user'
    post '/from_username', to: 'hub#from_username'
  end

  scope :curation do
    post '/create', to: 'curation#create'
    post '/create_personal', to: 'curation#create_personal'
    post '/get_by_name', to: 'curation#get_by_name'
    post '/get_listings_and_artists_by_name', to: 'curation#get_listings_and_artists_by_name'
    post '/get_private_content', to: 'curation#get_private_content'
    post '/get_viewer_private_content', to: 'curation#get_viewer_private_content'
    post '/publish_content', to: 'curation#publish_content'
    post '/unpublish_content', to: 'curation#unpublish_content'
    post '/save_draft_content', to: 'curation#save_draft_content'
    post '/update_approved_artists', to: 'curation#update_approved_artists'
    post '/update_name', to: 'curation#update_name'
    post '/check_name_availability', to: 'curation#check_name_availability'
    post '/get_by_approved_artist', to: 'curation#get_by_approved_artist'
    get '/get_highlighted_curations', to: 'curation#get_highlighted_curations'
    post '/get_by_listing_mint', to: 'curation#get_by_listing_mint'
    post '/generate_viewer_passcode', to: 'curation#generate_viewer_passcode'
    post '/update_self_as_approved_artists', to: 'curation#update_self_as_approved_artists'
    post '/get_all_curator_curations_with_private_hash', to: 'curation#get_all_curator_curations_with_private_hash'
    post '/hide_curation', to: 'curation#hide_curation'
  end

  scope :curation_listing do
    post '/submit_tokens', to: 'curation_listing#submit_tokens'
    post '/update_listing', to: 'curation_listing#update_listing'
    post '/cancel_listing', to: 'curation_listing#cancel_listing'
    post '/delete_submission', to: 'curation_listing#delete_submission'
    post '/delete_multiple_submissions', to: 'curation_listing#delete_multiple_submissions'
    post '/update_listing_metadata', to: 'curation_listing#update_listing_metadata'
    post '/get_listed_item', to: 'curation_listing#get_listed_item'
    post '/get_listings_by_parent', to: 'curation_listing#get_listings_by_parent'
    post '/update_edition_supply', to: 'curation_listing#update_edition_supply'
    post '/update_listing_status', to: 'curation_listing#update_listing_status'
  end

  scope :sales_history do
    post '/record_sale', to: 'sales_history#record_sale'
    post '/get_by_range', to: 'sales_history#get_by_range'
  end

  scope :key_hash do
    post '/upload', to: 'key_hash#upload'
    post '/get_hash', to: 'key_hash#get_hash'
  end

  scope :minted_indexer do
    post '/create', to: 'minted_indexer#create'
    post '/get_by_owner', to: 'minted_indexer#get_by_owner'
    post '/get_by_mint', to: 'minted_indexer#get_by_mint'
    post '/get_by_creator', to: 'minted_indexer#get_by_creator'
    post '/update_metadata', to: 'minted_indexer#update_metadata'
  end

  scope :waitlist_signup do
    get '/get_all', to: 'waitlist_signup#get_all'
    post '/create', to: 'waitlist_signup#create'
    post '/get_by_user_id', to: 'waitlist_signup#get_by_user_id'
    post '/approve_waitlist', to: 'waitlist_signup#approve_waitlist'
  end

  get '/auth/:provider/callback', to: "sessions#create"
  post '/auth/create', to: "social#create"
  post '/auth/destroy', to: "social#destroy"
  get '/twitter/profile_image', to: "twitter#profile_image"


  match '/rpc', to: "rpc#proxy", via: %w[get post]

  mount ActionCable.server => '/cable'
end
