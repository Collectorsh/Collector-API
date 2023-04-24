# frozen_string_literal: true

require 'httparty'
require 'json'
require_relative '../lib/metadata'

class UpdateMintVisibilityImageUrisJob < ApplicationJob
  queue_as :vis_image

  def priority
    5
  end

  def perform(mv)
    pda = Metadata.find_pda(mv.mint_address)
    return unless pda

    uri = pda[:uri]

    resp = HTTParty.get(uri)
    data = resp.body
    result = JSON.parse(data)
    mv.image = result['image']
    mv.save

    UploadImageJob.perform_later(result['image'], mv.mint_address)
  rescue StandardError => e
    Bugsnag.notify(e)
  end
end
