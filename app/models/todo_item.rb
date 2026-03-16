class TodoItem < ApplicationRecord
  belongs_to :issue

  validates :title, presence: true

  scope :ordered, -> { order(:position) }
  scope :completed, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }

  def complete!
    update!(completed: true)
  end

  def uncomplete!
    update!(completed: false)
  end

  def toggle!
    update!(completed: !completed)
  end
end
