class PrabhagStatusService
  def self.update_after_boundary_approval(prabhag)
    new(prabhag).update_after_boundary_approval
  end

  def self.update_after_boundary_rejection(prabhag)
    new(prabhag).update_after_boundary_rejection
  end

  def initialize(prabhag)
    @prabhag = prabhag
  end

  def update_after_boundary_approval
    return unless all_boundaries_approved?

    @prabhag.update!(status: 'approved')
  end

  def update_after_boundary_rejection
    return unless should_reject_prabhag?

    @prabhag.update!(status: 'rejected', assigned_to: nil)
  end

  private

  attr_reader :prabhag

  def all_boundaries_approved?
    prabhag.boundaries.pending.empty?
  end

  def should_reject_prabhag?
    no_pending_boundaries? && no_approved_boundaries?
  end

  def no_pending_boundaries?
    prabhag.boundaries.pending.empty?
  end

  def no_approved_boundaries?
    prabhag.boundaries.approved.empty?
  end
end