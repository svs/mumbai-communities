module WardsHelper
  def ward_activity_status(ward)
    if ward.fully_boundary_mapped?
      :active
    elsif ward.boundary_mapping_percentage > 0
      :growing
    else
      :inactive
    end
  end

  def ward_activity_color_class(ward)
    case ward_activity_status(ward)
    when :active then 'bg-green-500'
    when :growing then 'bg-yellow-500'
    else 'bg-gray-400'
    end
  end

  def ward_activity_status_text(ward)
    case ward_activity_status(ward)
    when :active then 'Active Community'
    when :growing then 'Growing Community'
    else 'Needs Boundary Mapping'
    end
  end

  def ward_activity_icon(ward)
    case ward_activity_status(ward)
    when :active then '🟢'
    when :growing then '🟡'
    else '⚪'
    end
  end
end
