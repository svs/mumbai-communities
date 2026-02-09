module HasPois
  extend ActiveSupport::Concern

  def pois(categories: nil)
    b = boundary || approved_boundary
    return [] unless b&.geojson.present?

    OsmService.pois_within(b.geojson, categories: categories)
  end
end
