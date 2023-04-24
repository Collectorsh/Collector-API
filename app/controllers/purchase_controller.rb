# frozen_string_literal: true

class PurchaseController < ApplicationController
  def verify
    user = User.find_by_api_key(params[:api_key])
    return render json: { status: 'error', msg: 'API Key not found' } unless user

    if Purchase.find_by(signature: params[:signature])
      return render json: { status: 'error',
                            msg: 'Transaction already exists' }
    end

    total = 0

    params[:order].each do |o|
      product = Product.find_by(id: o["id"])
      total += product.lamports * o["qty"]
    end

    return render json: { status: 'error', msg: 'Incorrect amount paid' } unless params[:amount] == total

    purchase = user.purchases.create!(public_key: params[:public_key], signature: params[:signature],
                                      lamports: params[:amount], order_number: SecureRandom.hex(4),
                                      order: params[:order].to_json, address: params[:address])

    result = nil
    while result.nil?
      result = verify_purchase(purchase)
      sleep(3)
    end

    purchase.update_attribute :result, result

    # Verify multiple transactions
    order = params[:order]
    instructions = result['transaction']['message']['instructions']
    Rails.logger.debug instructions.inspect
    wallets = order.uniq { |o| o['wallet'] }.map { |o| o['wallet'] }
    wallets.each do |w|
      total = 0
      order.select { |o| o['wallet'] == w }.each do |ord|
        p = Product.find_by(id: ord['id'])
        total += p.lamports * ord['qty']
      end
      Rails.logger.debug "Checking for payment for #{total} to wallet #{w}"
      trans = instructions.select { |i| i['parsed']['info']['destination'] == w }
      unless trans[0]
        return render json: { status: 'error',
                              msg: "Payment to #{w} not found in transaction" }
      end
      unless trans[0]['parsed']['info']['lamports'] == total
        return render json: { status: 'error',
                              msg: "Payment amount to #{w} is incorrect" }
      end
    end

    order.each do |o|
      p = Product.find_by(id: o['id'])
      next unless p.supply

      p.update_attribute(:supply, p.supply - o['qty'].to_i)
    end

    purchase.verified = true
    purchase.save!

    SendOrderEmailJob.perform_later(purchase)

    render json: { status: 'success', order_number: purchase.order_number }
    # rescue StandardError => e
    #   Bugsnag.notify(e)
    #   render json: { status: 'error', msg: e.message }
  end

  def verify_purchase(purchase)
    method_wrapper = SolanaRpcRuby::MethodsWrapper.new

    response = method_wrapper.get_transaction(
      purchase.signature,
      encoding: 'jsonParsed'
    )
    response.parsed_response['result']
  end
end
