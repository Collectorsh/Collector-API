# frozen_string_literal: true

gem 'activerecord-import'

class VisibilityController < ApplicationController
  # def old_set_visibility_and_order
  #   user = User.find_by_api_key(params[:api_key])
  #   return render json: { status: 'error', msg: 'Api key not valid' } unless user

  #   user.update_attribute(:columns, params[:columns]) if params[:columns]

  #   mints = MintVisibility.where(user_id: user.id).pluck(:mint_address)
  #   mints -= params[:tokens].collect { |t| t['mint'] }.flatten
  #   MintVisibility.where(user_id: user.id, mint_address: mints).delete_all

  #   MintVisibility.transaction do
  #     params[:tokens].each do |token|
  #       visibility = MintVisibility.find_or_initialize_by(user_id: user.id, mint_address: token['mint'])
  #       visibility.assign_attributes(
  #         visible: token['visible'],
  #         order_id: token['order_id'],
  #         accept_offers: token['accept_offers'],
  #         image: token['uri'],
  #         span: token['span'],
  #       )
  #       visibility.save!
  #     end
  #   end

  #   render json: { status: 'success' }
  # end

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

    return render json: { mints: [], default: true } if user.nil?

    render json: { mints: user.mint_visibilities, default: user.default_visibility }
  end
end
