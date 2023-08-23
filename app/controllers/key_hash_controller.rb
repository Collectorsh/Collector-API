class KeyHashController < ApplicationController
  before_action :is_authorized, except: [:get_hash]

  def upload
    KeyHash.create(name: params[:name], hash: params[:hash])

    render json: { status: 'success', msg: 'KeyHash created' }
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  def get_hash
    key_hash = KeyHash.find_by(name: params[:name])
    render json: key_hash
  rescue StandardError => e
    render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
  end

  private

  def is_authorized
    user = User.find_by_api_key(params[:api_key])
    authorized = user && user.id == 5421 #EV3 user id
    return render json: { status: 'error', msg: 'Api key not valid' } unless authorized 
  end
end
