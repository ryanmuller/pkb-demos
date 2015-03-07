require "sqlite3"
require "faraday"
require "yaml"
require "nokogiri"

def configuration
  path = File.join File.dirname(__FILE__), "secrets.yml"
  YAML.load_file path
end

conn = Faraday.new(url: "https://api.pinboard.in/v1/") do |faraday|
  faraday.request :url_encoded
  faraday.adapter :net_http
end
conn.basic_auth(configuration["pinboard_username"], configuration["pinboard_password"])

resp = conn.get "posts/all"
resp_xml = Nokogiri::XML(resp.body)
source_urls = resp_xml.xpath("//post/@href").map(&:value)

db = PopulateDB.new("pinboard.in_#{configuration["pinboard_username"]}.db")

source_urls.each do |source_url|
  db.insert :sources, url: source_url
end
