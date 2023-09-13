# frozen_string_literal: true

require_relative '../lib/btc'

class ApiKeyController < ApplicationController
  def request_api_key
    nonce = SecureRandom.hex(4)

    unless (user = User.where("public_keys LIKE '%#{params[:publicKey]}%'").first)
      user = User.create(public_keys: [params[:publicKey]])
    end

    user.nonce = nonce
    user.save!

    render json: { status: 'success', nonce: user.nonce }
  end

  def create_api_key
    user = User.where("public_keys LIKE '%#{params[:publicKey]}%' AND nonce ='#{params[:nonce]}'").first
    return render json: { status: 'error', msg: 'Public key or nonce not found' } unless user

    return render json: { status: 'error', msg: 'Signature verifcation failed' } unless verify_signature(
      params[:publicKey], user.nonce
    )

    user.api_key = SecureRandom.hex(16)
    user.save!
    render json: { status: 'success', user: user }
  end

  private

  def verify_signature(public_key, nonce)
    verify_key = RbNaCl::VerifyKey.new(decode_base58(public_key))
    signature = params[:signature]['data'].pack('c*')
    message = "#{Rails.configuration.sign_message}#{nonce}"
    puts "messgae: #{message}"
    Rails.logger.debug message
    verify_key.verify(signature, message)
  rescue RbNaCl::BadSignatureError
    false
  end

  def decode_base58(str)
    Btc::Base58.data_from_base58 str
  end
end
