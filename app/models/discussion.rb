class Discussion < ApplicationRecord
  belongs_to :user
  belongs_to :discussable, polymorphic: true, optional: true
  belongs_to :category, optional: true
  has_many :posts, dependent: :destroy

  validates :title, presence: true
  validates :body, presence: true
  validates :status, inclusion: { in: %w[open closed archived] }

  scope :open, -> { where(status: "open") }
  scope :closed, -> { where(status: "closed") }
  scope :archived, -> { where(status: "archived") }
  scope :pinned, -> { where(pinned: true) }
  scope :not_archived, -> { where.not(status: "archived") }
  scope :recent, -> { order(pinned: :desc, last_post_at: :desc, created_at: :desc) }
  scope :search, ->(query) {
    where("title LIKE :q OR body LIKE :q", q: "%#{query}%") if query.present?
  }

  def open?
    status == "open"
  end

  def closed?
    status == "closed"
  end

  def archived?
    status == "archived"
  end

  def close!
    update!(status: "closed")
  end

  def reopen!
    update!(status: "open")
  end

  def archive!
    update!(status: "archived")
  end

  def pin!
    update!(pinned: true)
  end

  def unpin!
    update!(pinned: false)
  end

  def touch_last_post
    update_column(:last_post_at, Time.current)
  end
end
