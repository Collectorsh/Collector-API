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

  # def visibility_and_order
  #   user = User.where("public_keys LIKE '%#{params[:public_key]}%'").last
  #   userTokens = params[:tokens] || []
  #   userTokenMints = userTokens.map { |token| token['mint'] }
  #   return render json: { mints: [], default: true } if user.nil?
  #   # render json: { mints: user.mint_visibilities, default: user.default_visibility }

  #   mint_visibilities = user.mint_visibilities

  #   optimized_images = OptimizedImage.where(mint_address: userTokenMints).index_by(&:mint_address)

  #   results = userTokens.map do |token|
  #     mint = token['mint']
  #     mint_visibility = mint_visibilities.find { |mv| mv.mint_address == mint }
  #     optimized_image = optimized_images[mint]

  #     default = { 
  #       order_id: nil,
  #       visible: user['default_visibility'],
  #       span: 1,
  #     }

  #     token.merge!(default) # merge default values into token

  #     token[:optimized] = optimized_image&.optimized if optimized_image
  #     token[:error_message] = optimized_image&.error_message if optimized_image

  #     token.merge!(mint_visibility&.attributes || {}) # mint visibilities should override defaults

  #     token
  #   end

  #   # # Merge mint_visibilities items not found in userTokenMints
  #   # remaining_mint_visibilities = mint_visibilities.reject { |mv| userTokenMints.include?(mv.mint_address) }

  #   # remaining = []
    
  #   # remaining_mint_visibilities.each do |mv|
  #   #   new_mv = mv.attributes.merge('mint' => mv['mint_address'])
  #   #   remaining << new_mv # Push the new hash into the array
  #   # end
  #   # results += remaining
      
  #   render json: { tokens: results, default: user.default_visibility }
  # rescue => e
  #   puts "error getting visibilities: #{e.message}"
  #   render json: { status: 'error', msg: "An error occurred: #{e.message}" }
  # end

  def visibility_and_order
    user = User.where("public_keys LIKE '%#{params[:public_key]}%'").last
    return render json: { mints: [], default: true } if user.nil?


    userTokenMints = params[:mints] || []
    optimizations = OptimizedImage.where(mint_address: userTokenMints).index_by(&:mint_address)
    visibilities = user.mint_visibilities.index_by(&:mint_address)

    render json: { visibilities: visibilities, optimizations: optimizations, user_default: user.default_visibility }

  rescue => e
    puts "error getting visibilities: #{e.message}"
    render json: { status: 'error', msg: "An error occurred: #{e.message}" }
  end

end
