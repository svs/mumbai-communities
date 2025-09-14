module ApplicationHelper
  def location_setup_banner
    return unless user_signed_in? && current_user.needs_location_setup?

    content_tag :div, class: "bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-6" do
      content_tag :div, class: "flex items-center justify-between" do
        content_tag(:div, class: "flex items-center") do
          content_tag(:i, "", class: "fas fa-map-marker-alt text-2xl mr-3 text-yellow-600") +
          content_tag(:div) do
            content_tag(:p, "Choose your ward and prabhag to see issues in your area", class: "font-semibold text-yellow-800") +
            content_tag(:p, "Help us show you the most relevant community tasks", class: "text-sm text-yellow-700")
          end
        end +
        content_tag(:div, class: "flex space-x-3") do
          link_to("Set Location", setup_location_path, class: "bg-yellow-600 hover:bg-yellow-700 text-white px-4 py-2 rounded-lg font-semibold transition-colors") +
          link_to("Skip", "#", class: "text-yellow-600 hover:text-yellow-800 px-4 py-2 text-sm")
        end
      end
    end
  end

  def user_location_summary
    return unless user_signed_in? && current_user.has_location?

    content_tag :div, class: "bg-green-50 border border-green-200 rounded-lg p-3 text-sm" do
      content_tag(:i, "", class: "fas fa-map-marker-alt text-green-600 mr-2") +
      content_tag(:span, "Your area: ", class: "text-green-600 font-semibold") +
      content_tag(:span, current_user.location_summary, class: "text-green-800") +
      " " +
      link_to("Change", setup_location_path, class: "text-green-600 hover:text-green-800 underline text-xs")
    end
  end
end
