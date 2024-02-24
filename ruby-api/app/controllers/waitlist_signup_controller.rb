# frozen_string_literal: true

class WaitlistSignupController < ApplicationController
  def get_all
    signups = WaitlistSignup.includes(:user)

    puts "signups #{signups.inspect}"

    custom_json = signups.map do |signup|
      signup_attributes = signup.attributes
      user_attributes = signup.user.public_info
      signup_attributes.merge({ user: user_attributes })
    end

    render json: custom_json
  rescue StandardError => e
    render json: { error: e.message }, status: 500
  end

  def get_by_user_id
    signup = WaitlistSignup.where(user_id: params[:user_id]).first
    render json: signup
  rescue StandardError => e
    render json: { error: e.message }, status: 500
  end

  def create
    valid_user = User.find_by(id: params[:user_id])

    unless valid_user && valid_user.username.present?
      return render json: { error: 'Invalid User' }, status: 400
    end

    signup = WaitlistSignup.create(
      user_id: params[:user_id],
      twitter_handle: params[:twitter_handle],
      email: params[:email],
      more_info: params[:more_info]
    )

    if signup.errors.any?
      render json: { error: signup.errors.full_messages }, status: 400
    else
      render json: signup, status: :created
    end
  rescue StandardError => e
    render json: { error: e.message }, status: 500
  end

  def approve_waitlist
    admin = User.find_by_api_key(params[:api_key])
    adminIDs = [
      720, #Nate (username: n8solomon)
      5421, #Scott (username: EV3)
    ]
    authorized = admin && adminIDs.include?(admin.id)

    unless authorized 
      return render json: { error: 'Unauthorized' }, status: 401
    end

    user = User.find_by(id: params[:user_id])
    user.update(subscription_level: "pro")

    render json: { success: true}
  rescue StandardError => e
    render json: { error: e.message }, status: 500
  end
end
