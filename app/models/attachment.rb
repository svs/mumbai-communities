class Attachment < ApplicationRecord
  belongs_to :attachable, polymorphic: true
  has_one_attached :file

  validates :name, presence: true
  validates :attachment_type, inclusion: { in: %w[link file] }
  validates :url, presence: true, if: -> { attachment_type == 'link' }
  validates :file, presence: true, if: -> { attachment_type == 'file' }

  scope :links, -> { where(attachment_type: 'link') }
  scope :files, -> { where(attachment_type: 'file') }
  scope :ordered, -> { order(:position, :created_at) }

  before_save :set_mime_type, if: -> { file.attached? }

  def link?
    attachment_type == 'link'
  end

  def file?
    attachment_type == 'file'
  end

  def primary?
    position == 1
  end

  private

  def set_mime_type
    self.mime_type = file.blob.content_type if file.attached?
  end
end