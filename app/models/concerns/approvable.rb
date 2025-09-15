module Approvable
  extend ActiveSupport::Concern

  included do
    # These associations and validations are expected to be defined by the including model
    # belongs_to :approved_by, class_name: 'User', optional: true
    # validates :status, inclusion: { in: ['pending', 'approved', 'rejected', ...] }

    scope :approved, -> { where(status: 'approved') }
    scope :pending, -> { where(status: 'pending') }
    scope :rejected, -> { where(status: 'rejected') }
  end

  def approved?
    status == 'approved'
  end

  def pending?
    status == 'pending'
  end

  def rejected?
    status == 'rejected'
  end

  def approvable?
    pending?
  end

  def rejectable?
    pending? || approved?
  end
end