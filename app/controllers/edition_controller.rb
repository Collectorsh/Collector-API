# frozen_string_literal: true

require_relative '../lib/btc'

class EditionController < ApplicationController
  def editiondata
    return unless params[:data]

    response = extract_editiondata(params[:data])
    render json: response.to_json
  end

  def batch_editiondata
    return unless params[:data]

    response = []
    params[:data].each do |d|
      response << extract_editiondata(d['data'][0])
    end
    render json: response.to_json
  end

  def extract_editiondata(data)
    edition_data = {}
    data = Base64.decode64(data)
    edition_data[:type] = data[0].ord
    edition_data[:name] = edition_types[data[0].ord]
    # Master Edition
    if (data[0].ord == 2 || data[0].ord == 6) && data[9]&.ord != 0
      edition_data[:max_supply] = data[10..17].unpack1('I*')
      edition_data[:supply] = data[1..8].unpack1('I*')
    end
    if data[0].ord == 1
      edition_data[:parent] = Btc::Base58.base58_from_data(data[1..32].unpack('H*').pack('H*'))
      edition_data[:number] = data[33..40].unpack1('I*')
    end
    edition_data
  end

  private

  def edition_types
    [
      'Uninitialized',
      'Edition',
      'Master Edition',
      'Reservation List',
      'Metadata',
      'Reservation List',
      'Master Edition',
      'Edition Marker'
    ]
  end
end
