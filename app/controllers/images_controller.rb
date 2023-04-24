# frozen_string_literal: true

class ImagesController < ApplicationController
  def upload
    params[:images].each do |image|
      next if UploadedImage.find_by(mint: image['mint'])

      UploadImageJob.perform_later(image['uri'], image['mint'])
    end
  end
end
