json.array!(@issues) do |issue|
  json.extract! issue, :id, :id, :url, :title, :body, :created_at, :updated_at
  json.url issue_url(issue, format: :json)
end
