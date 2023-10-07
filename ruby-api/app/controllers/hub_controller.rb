# frozen_string_literal: true

class HubController < ApplicationController
  def fetch_config
    return render json: { status: 'error', msg: 'API Key missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'API Key not found' } unless user
    return render json: { status: 'missing', msg: 'Not configured' } unless user.hub

    allowed_users = User.where(id: user.allowed_users).as_json(except: %i[api_key
                                                                          public_key public_keys])

    render json: { status: "success", hub: user.hub, allowed_users: allowed_users }
  end

  def save_config
    return render json: { status: 'error', msg: 'API Key missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'API Key not found' } unless user

    hub_config = Hub.where(user_id: user.id).first_or_create!
    hub_config.name = params[:name]
    hub_config.description = params[:description]
    hub_config.auction_house = params[:auction_house]
    hub_config.save!

    render json: { status: "success", hub: hub_config }
  end

  def fetch_all_users
    return render json: { status: 'error', msg: 'API Key missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'API Key not found' } unless user

    users = User.where.not(id: user.allowed_users).where("username IS NOT NULL")
                .as_json(except: %i[api_key public_key public_keys])

    render json: { status: "success", all_users: users }
  end

  def add_user
    return render json: { status: 'error', msg: 'API Key missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'API Key not found' } unless user

    user.update_attribute :allowed_users, user.allowed_users << params[:id]

    all_users = User.where.not(id: user.allowed_users).where("username IS NOT NULL")
                    .as_json(except: %i[api_key public_key public_keys])

    allowed_users = User.where(id: user.allowed_users).as_json(except: %i[api_key
                                                                          public_key public_keys])

    render json: { status: "success", all_users: all_users, allowed_users: allowed_users }
  end

  def remove_user
    return render json: { status: 'error', msg: 'API Key missing' } unless params[:api_key]

    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'API Key not found' } unless user

    user.update_attribute :allowed_users, user.allowed_users - [params[:id]]

    all_users = User.where.not(id: user.allowed_users).where("username IS NOT NULL")
                    .as_json(except: %i[api_key public_key public_keys])

    allowed_users = User.where(id: user.allowed_users).as_json(except: %i[api_key
                                                                          public_key public_keys])

    render json: { status: "success", all_users: all_users, allowed_users: allowed_users }
  end

  def from_username
    return render json: { status: 'error', msg: 'Username missing' } unless params[:username]

    user = User.find_by_username(params[:username])
    return render json: { status: 'error', msg: 'Username not found' } unless user
    return render json: { status: 'error', msg: 'No hub found' } unless user.hub

    render json: { status: "success", hub: user.hub, allowed_users: user.allowed_users }
  end
end
