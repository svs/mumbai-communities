class Post < ApplicationRecord
  belongs_to :discussion, counter_cache: true
  belongs_to :user
  belongs_to :parent, class_name: "Post", optional: true
  has_many :replies, class_name: "Post", foreign_key: :parent_id, dependent: :destroy

  validates :body, presence: true

  before_create :set_depth
  after_create :touch_discussion

  scope :roots, -> { where(parent_id: nil) }
  scope :chronological, -> { order(:created_at) }

  private

  def set_depth
    self.depth = parent ? parent.depth + 1 : 0
  end

  def touch_discussion
    discussion.touch_last_post
  end
end
