class MintedIndexerController < ApplicationController
  before_action :get_authorized_user, only: [:create]

  def create

    user = @authorized_user

    token = params[:token]

    owner_address = token['owner_address']
    artist_address = token['artist_address']
    owner_id = params[:owner_id] || (owner_address.present? ? User.find_by("public_keys LIKE ?", "%#{owner_address}%")&.id : nil)
    artist_id = params[:artist_id] || (artist_address.present? ? User.find_by("public_keys LIKE ?", "%#{artist_address}%")&.id : nil)

    minted_indexer = MintedIndexer.create({
      mint: token['mint'],
      name: token['name'],
      owner_id: owner_id,
      owner_address: owner_address,
      artist_id: artist_id,
      artist_address: artist_address,
      animation_url: token['animation_url'],
      image: token['image'],
      description: token['description'],
      primary_sale_happened: token['primary_sale_happened'],
      is_edition: token['is_edition'],
      parent: token['parent'],
      is_master_edition: token['is_master_edition'],
      supply: token['supply'],
      max_supply: token['max_supply'],
      creators: token['creators'],
      files: token['files'],
      royalties: token['royalties'],
      is_collection_nft: token['is_collection_nft'],
    })

    if minted_indexer.errors.any?
      puts "Failed to save index for #{token['mint']}: #{minted_indexer.errors.full_messages.join(", ")}"
    else
      return render json: { status: 'success', minted: minted_indexer.to_json }
    end

  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_by_owner
    minted_indexer = MintedIndexer.where(owner_address: params[:owner_address])

    if minted_indexer
      return render json: { status: 'success', mints: minted_indexer }
    else
      return render json: { status: 'error', msg: 'Mint not found' }
    end
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_by_creator
    minted_indexer = MintedIndexer.where("EXISTS (
      SELECT 1 FROM json_array_elements_text(creators::json) as elem
      WHERE json_extract_path_text(elem::json, 'address') = ?
    )", params[:artist_address])

    if minted_indexer
      return render json: { status: 'success', mints: minted_indexer }
    else
      return render json: { status: 'error', msg: 'Mint not found' }
    end
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_by_mint
    minted_indexer = MintedIndexer.find_by(mint: params[:mint])
    if minted_indexer
      return render json: { status: 'success', mint: minted_indexer }
    else
      return render json: { status: 'error', msg: 'Mint not found' }
    end
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  private
  
  def get_authorized_user
    return render json: { status: 'error', msg: 'Auth missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'Api key not valid' } unless user 

    @authorized_user = user
  end
end