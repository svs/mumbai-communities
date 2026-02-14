class WardDataSnapshot < ApplicationRecord
  belongs_to :ward, foreign_key: "ward_code", primary_key: "ward_code", optional: true

  validates :source_url, presence: true
  validates :data_type, presence: true

  DATA_TYPES = %w[rti docs financial election arcgis_layer].freeze
  validates :data_type, inclusion: { in: DATA_TYPES }

  scope :for_ward, ->(ward_code) { where(ward_code: ward_code) }
  scope :of_type, ->(data_type) { where(data_type: data_type) }
  scope :latest, -> { order(created_at: :desc) }

  def compute_content_hash
    Digest::SHA256.hexdigest(content) if content
  end

  def content_changed_from?(previous_snapshot)
    return true if previous_snapshot.nil?
    content_hash != previous_snapshot.content_hash
  end
end
