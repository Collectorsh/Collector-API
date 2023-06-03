# frozen_string_literal: true

class GalleriesController < ApplicationController
  def get
    galleries = User.select(:username, :twitter_profile_image).where("username IS NOT NULL")
    render json: galleries
  end

  def new
    results = []
    found = 0

    User.where("username IS NOT NULL").order(created_at: :desc).each do |user|
      unless (mv = user.mint_visibilities.where("image IS NOT NULL AND order_id IS NOT NULL AND visible = true").order(order_id: :asc).limit(1).first)
        next
      end

      results << { username: user.username, twitter_profile_image: user.twitter_profile_image, image: mv.image,
                   mint: mv.mint_address }

      found += 1
      break if found == 8
    end

    render json: results
  end

  def popular
    results = []
    found = 0

    User.where("username IS NOT NULL AND dao = false").order(views: :desc).each do |user|
      unless (mv = user.mint_visibilities.where("image IS NOT NULL AND order_id IS NOT NULL AND visible = true").order(
        order_id: :asc, created_at: :desc
      ).limit(1).first)
        next
      end

      results << { username: user.username, twitter_profile_image: user.twitter_profile_image, image: mv.image,
                   mint: mv.mint_address }

      found += 1
      break if found == 8
    end

    render json: results
  end

  def daos
    results = []
    found = 0

    User.where("username IS NOT NULL AND dao = true").order(views: :desc).each do |user|
      unless (mv = user.mint_visibilities.where("image IS NOT NULL AND order_id IS NOT NULL AND visible = true").order(order_id: :asc).limit(1).first)
        next
      end

      results << { username: user.username, twitter_profile_image: user.twitter_profile_image, image: mv.image,
                   mint: mv.mint_address }

      found += 1
    end

    render json: results
  end

  def sample
    users = User.where("username IS NOT NULL AND views > 100")
    users.shuffle.each do |user|
      @user = user
      @mv = user.mint_visibilities.where("image IS NOT NULL AND order_id IS NOT NULL AND visible = true")
      break if @mv
    end
    mint = @mv.shuffle.pluck(:mint_address).first
    render json: { username: @user.username, twitter: @user.twitter_profile_image, mint: mint }
  end

  def curated
    results = []
    found = 0

    usernames = ENV['CURATED_GALLERIES'].split(',') # Split the environment variable value into an array of usernames
    users = User.where(username: usernames).order(views: :desc).each do |user|
      unless (mv = user.mint_visibilities.where("image IS NOT NULL AND order_id IS NOT NULL AND visible = true").order(order_id: :asc).limit(1).first)
        next
      end

      results << { username: user.username, twitter_profile_image: user.twitter_profile_image, image: mv.image,
                   mint: mv.mint_address }

      found += 1
      
    end
    render json: results
  end
end
