json.features do
  json.array! [@boundary] do |boundary|
    json.partial! 'boundaries/boundary', boundary: boundary, context: 'review'
  end
end