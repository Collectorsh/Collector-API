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
      unless (mv = user.mint_visibilities.where("order_id IS NOT NULL AND visible = true").order(order_id: :asc).limit(1).first)
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
      unless (mv = user.mint_visibilities.where("order_id IS NOT NULL AND visible = true").order(
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
      unless (mv = user.mint_visibilities.where("order_id IS NOT NULL AND visible = true").order(order_id: :asc).limit(1).first)
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
      @mv = user.mint_visibilities.where("order_id IS NOT NULL AND visible = true")
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
      unless (mv = user.mint_visibilities.where("order_id IS NOT NULL AND visible = true").order(order_id: :asc).limit(1).first)
        next
      end

      results << { username: user.username, twitter_profile_image: user.twitter_profile_image, image: mv.image,
                   mint: mv.mint_address }

      found += 1
      
    end
    render json: results
  end



  def get_all
    users = User.joins(:mint_visibilities)
                .where("username IS NOT NULL")
                .where("EXISTS (
                      SELECT 1
                      FROM mint_visibilities mv
                      WHERE mv.user_id = users.id
                        AND mv.order_id IS NOT NULL
                        AND mv.visible = true
                    )")
                .distinct

    # Search by username
    if params[:search].present?
      users = users.where("username ILIKE ?", "%#{params[:search]}%")
    end

    # Sorting by username in ascending order
    users = users.order(username: :asc)

    # Count of total possible options
    total_options_count = users.count

    users = users.paginate(page: params[:page], per_page: params[:per_page] || 10)

  
    results = users.map do |user|
      image = user.mint_visibilities.find_by("order_id = 1 AND visible = true")&.image || user.mint_visibilities.find_by("order_id IS NOT NULL AND visible = true")&.image
      mint = user.mint_visibilities.find_by("order_id = 1 AND visible = true")&.mint_address || user.mint_visibilities.find_by("order_id IS NOT NULL AND visible = true")&.mint_address
      {
        username: user.username,
        twitter_profile_image: user.twitter_profile_image,
        image: image,
        mint: mint
      }
    end.compact

    render json: { galleries: results, total: total_options_count }
  end
end
