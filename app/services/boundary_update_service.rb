class BoundaryUpdateService
  def self.update_with_admin_tracking(boundary, params, admin_user)
    new(boundary, params, admin_user).update_with_admin_tracking
  end

  def initialize(boundary, params, admin_user)
    @boundary = boundary
    @params = params
    @admin_user = admin_user
  end

  def update_with_admin_tracking
    handle_geojson_update if geojson_updated?
    @boundary.assign_attributes(@params.except(:geojson))
    @boundary.save
  end

  private

  attr_reader :boundary, :params, :admin_user

  def geojson_updated?
    params[:geojson].present? && params[:geojson] != boundary.geojson
  end

  def handle_geojson_update
    boundary.geojson = params[:geojson]
    boundary.edited_by = admin_user
  end
end