# Individual prabhag show - only show the prabhag boundary to focus the map correctly
json.features do
  json.partial! 'prabhags/prabhag', prabhag: @prabhag, boundary: @prabhag.boundary
end