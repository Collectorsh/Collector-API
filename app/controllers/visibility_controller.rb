# frozen_string_literal: true

gem 'activerecord-import'

class VisibilityController < ApplicationController
  def set_visibility_and_order
    begin
      user = User.find_by_api_key(params[:api_key])

      return render json: { status: 'error', msg: 'Api key not valid' } unless user

      user.update_attribute(:columns, params[:columns]) if params[:columns]

      mint_visibility_attrs = params[:tokens].map do |token|
        {
          user_id: user.id,
          mint_address: token['mint'],
          visible: token['visible'],
          order_id: token['order_id'],
          accept_offers: token['accept_offers'],
          image: token['uri'],
          span: token['span'],
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      MintVisibility.upsert_all(mint_visibility_attrs, unique_by: [:user_id, :mint_address])

      render json: { status: 'success' }

    rescue => e
      puts "error: #{e.message}"
      render json: { status: 'error', msg: "An error occurred: #{e.message}" }
    end
  end

  def visibility_and_order
    user = User.where("public_keys LIKE '%#{params[:public_key]}%'").last
    userTokenMints = params[:mints]

    return render json: { mints: [], default: true } if user.nil?
    # render json: { mints: user.mint_visibilities, default: user.default_visibility }

    mint_visibilities = user.mint_visibilities

    optimized_images = OptimizedImage.where(mint_address: userTokenMints).index_by(&:mint_address)

    results = userTokenMints.map do |mint|
      mint_visibility = mint_visibilities.find { |mv| mv.mint_address == mint }
      optimized_image = optimized_images[mint]
      merged_hash = {
        order_id: nil,
        visible: user.default_visibility,
        span: 1,
        mint_address: mint,
      }
      merged_hash[:optimized] = optimized_image&.optimized if optimized_image
      merged_hash[:error_message] = optimized_image&.error_message if optimized_image

      merged_hash.merge!(mint_visibility&.attributes || {})

      merged_hash
    end
    
    render json: { mints: results, default: user.default_visibility }
  rescue => e
    puts "error getting visibilities: #{e.message}"
    render json: { status: 'error', msg: "An error occurred: #{e.message}" }
  end
end
