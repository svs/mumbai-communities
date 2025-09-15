json.features do
  @boundaries_for_review.each do |boundary|
    json.partial! 'boundaries/boundary', boundary: boundary, context: 'review'
  end
end