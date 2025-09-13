class Ticket < ApplicationRecord
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User'
  belongs_to :ward, foreign_key: 'ward_code', primary_key: 'ward_code'
  belongs_to :prabhag, -> { where('prabhag_number IS NOT NULL') }, 
             foreign_key: ['prabhag_number', 'ward_code'], 
             primary_key: ['number', 'ward_code'], 
             optional: true
  
  validates :title, presence: true
  validates :description, presence: true
  validates :ticket_type, presence: true, inclusion: { 
    in: %w[boundary_mapping road_repair photo_report infrastructure complaint other] 
  }
  validates :ward_code, presence: true
  validates :status, presence: true, inclusion: { 
    in: %w[open assigned in_progress submitted under_review approved closed rejected] 
  }
  validates :priority, presence: true, inclusion: { 
    in: %w[low medium high urgent] 
  }
  
  scope :open, -> { where(status: 'open') }
  scope :assigned, -> { where(status: 'assigned') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :submitted, -> { where(status: 'submitted') }
  scope :under_review, -> { where(status: 'under_review') }
  scope :completed, -> { where(status: ['approved', 'closed']) }
  scope :overdue, -> { where('due_date < ? AND status NOT IN (?)', Time.current, ['approved', 'closed']) }
  scope :for_ward, ->(ward_code) { where(ward_code: ward_code) }
  scope :boundary_mapping, -> { where(ticket_type: 'boundary_mapping') }
  
  before_create :set_defaults
  
  def can_be_assigned_to?(user)
    status == 'open'
  end
  
  def assign_to!(user)
    update!(assigned_to: user, status: 'assigned')
  end
  
  def start_work!
    update!(status: 'in_progress')
  end
  
  def submit_for_review!
    update!(status: 'submitted')
  end
  
  def approve!
    update!(status: 'approved')
  end
  
  def close!
    update!(status: 'closed')
  end
  
  def reject!
    update!(status: 'rejected', assigned_to: nil)
  end
  
  def overdue?
    due_date.present? && due_date < Time.current && !completed?
  end
  
  def completed?
    ['approved', 'closed'].include?(status)
  end
  
  def days_remaining
    return nil unless due_date.present?
    
    (due_date.to_date - Date.current).to_i
  end
  
  private
  
  def set_defaults
    self.status ||= 'open'
    self.priority ||= 'medium'
    self.due_date ||= 7.days.from_now if ticket_type == 'boundary_mapping'
  end
end
