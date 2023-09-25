class CurationHighlight < ApplicationRecord
  def fetch_curations
    # Curation.includes(:curator, :curation_listings)
    #         .where(id: self.curation_ids, is_published: true)
    #         .map(&:condensed_with_curator)

    curations = Curation.includes(:curator, :curation_listings).where(id: self.curation_ids, is_published: true).to_a
    ordered_curations = self.curation_ids.map { |id| curations.find { |curation| curation.id == id } }.compact
    ordered_curations.map(&:condensed_with_curator)
  end
end
