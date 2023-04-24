# frozen_string_literal: true

class FeaturedController < ApplicationController
  def wins
    sql = "SELECT user_id, count(*) as count FROM bids WHERE end_time < #{Time.now.to_i} AND outbid = false
           AND created_at > '#{Time.now - 7.days}'
           GROUP BY user_id ORDER BY count DESC LIMIT 5"
    records = ActiveRecord::Base.connection.execute(sql)

    results = []

    records.each do |r|
      user = User.find_by_id(r['user_id'])
      user = User.find_by_id(user.parent_id) if user.parent_id
      results << { user: { username: user.username, twitter_profile_image: user.twitter_profile_image },
                   wins: r['count'] }
    end

    render json: results
  end

  def followers
    sql = "SELECT following_id, count(*) as count FROM user_followings
           GROUP BY following_id ORDER BY count DESC LIMIT 5"
    records = ActiveRecord::Base.connection.execute(sql)

    results = []

    records.each do |r|
      user = User.find_by_id(r['following_id'])
      user = User.find_by_id(user.parent_id) if user.parent_id
      results << { user: { username: user.username, twitter_profile_image: user.twitter_profile_image },
                   followers: r['count'] }
    end

    render json: results
  end

  def artists
    sql = "SELECT artist, count(*) as count FROM follows
           GROUP BY artist ORDER BY count DESC LIMIT 5"
    records = ActiveRecord::Base.connection.execute(sql)

    results = []

    records.each do |r|
      artist = ArtistName.find_by_name(r['artist'])
      results << { artist: artist, followers: r['count'] }
    end

    render json: results
  end

  def marketplace_stats
    results = []
    sql = "SELECT source, count(*) as count, sum(highest_bid) as total
           FROM auctions
           WHERE end_time > #{(Time.now - 7.days).to_i}
           AND end_time < #{Time.now.to_i}
           AND number_bids > 0
           GROUP BY source"
    records = ActiveRecord::Base.connection.execute(sql)
    records.each do |r|
      results << { name: r['source'], volume: r['total'],
                   results: [type: 'auction', count: r['count'], total: r['total']] }
    end
    sql = "SELECT source, transaction_type, count(*) as count, sum(amount) as total
           FROM marketplace_sales
           WHERE timestamp > #{(Time.now - 7.days).to_i}
           AND timestamp < #{Time.now.to_i}
           GROUP BY source, transaction_type"
    records = ActiveRecord::Base.connection.execute(sql)
    records.each do |r|
      if (result = results.find { |rs| rs[:name] == r['source'] })
        result[:volume] = result[:volume] + r['total']
        result[:results] << { type: r['transaction_type'], count: r['count'], total: r['total'] }
      else
        results << { name: r['source'], volume: r['total'],
                     results: [type: r['transaction_type'], count: r['count'], total: r['total']] }
      end
    end

    results.each do |result|
      result[:results] = result[:results].sort_by { |r| r[:total] }.reverse
    end

    render json: results.sort_by { |r| r[:volume] }.reverse
  end
end
