class Curation < ApplicationRecord
  belongs_to :curator, class_name: 'User', foreign_key: 'curator_id'
  has_many :curation_listings

  delegate :basic_info, to: :curator, prefix: true

  validates :name, allow_nil: false, uniqueness: { case_sensitive: false }
  validates_format_of :name, with: /\A(?!.*[_-]{2})[a-zA-Z0-9_-]{2,31}\z/, message: "Name needs to be url friendly"

  def public_info
    attributes.except('draft_content', 'private_key_hash', 'viewer_passcode')
  end 

  def approved_artists
    User.where(id: approved_artist_ids).map(&:public_info)
  end

  # def submitted_token_listings
  #   CurationListing.where(curation_id: self.id, mint: self.submitted_token_mints)
  # end

  def condensed
    content = self.is_published ? self.published_content : self.draft_content

    content ||= {}

    # Merge the description and banner_image to the top level
    condensed_attributes = self.attributes.merge(
      description_delta: content['description_delta'],
      description: content['description'],
      banner_image: content['banner_image']
    )

    # Remove draft_content and published_content attributes
    condensed_attributes.except!('draft_content', 'published_content', 'private_key_hash')

    condensed_attributes
  end

  def condensed_with_curator
    result = condensed
    
    # Merge the curator's public info
    result.merge(curator: self.curator.public_info)
  end

  def condensed_with_curator_and_listings
    result = condensed
    
    # Merge the curator's public info
    result = result.merge(curator: self.curator.public_info)

    
    # Add the submitted tokens' attributes
    result[:submitted_token_listings] = self.curation_listings.map(&:attributes)
    
    result
  end

  def basic_info
    #only get the id, name and curators name
    attributes.slice('id', 'name').merge(curator: self.curator.public_info)
  end
end