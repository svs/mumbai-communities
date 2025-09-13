class Ward < ApplicationRecord
  has_many :prabhags, foreign_key: 'ward_code', primary_key: 'ward_code'
  has_many :tickets, foreign_key: 'ward_code', primary_key: 'ward_code'
  
  validates :ward_code, presence: true, uniqueness: true
  validates :name, presence: true
  
  scope :geocoded, -> { where(is_geocoded: true) }
  scope :not_geocoded, -> { where(is_geocoded: false) }
  
  def completion_percentage
    return 0 if prabhags.count.zero?
    
    mapped_prabhags = prabhags.select { |p| p.boundary_geojson.present? }.count
    (mapped_prabhags.to_f / prabhags.count * 100).round(1)
  end
  
  def total_tickets
    tickets.count
  end
  
  def open_tickets
    tickets.where(status: ['open', 'assigned', 'in_progress']).count
  end
  
  def completed_tickets
    tickets.where(status: ['approved', 'closed']).count
  end
  
  def overdue_tickets
    tickets.where('due_date < ? AND status NOT IN (?)', Time.current, ['approved', 'closed']).count
  end
  
  # Check if ward has all prabhags mapped
  def fully_mapped?
    return false if prabhags.count.zero?
    
    prabhags.all? { |p| p.boundary_geojson.present? }
  end
  
  # Get ward center from mapped prabhags
  def center_coordinates
    return nil unless fully_mapped?
    
    # Calculate centroid from all prabhag boundaries
    # This is a simplified calculation - in production you'd use proper GIS
    boundaries = prabhags.map(&:boundary_center).compact
    return nil if boundaries.empty?
    
    avg_lat = boundaries.sum { |coords| coords[0] } / boundaries.size
    avg_lng = boundaries.sum { |coords| coords[1] } / boundaries.size
    [avg_lat, avg_lng]
  end
end
