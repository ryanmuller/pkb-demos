require "classifier"
require "htmlentities"
require "sanitize"
require "sqlite3"

def convert(content_html)
  coder = HTMLEntities.new
  content = Sanitize.fragment(coder.decode(content_html))
  content.downcase.gsub(/[^a-zA-Z0-9\-\s]/, "")
end

db = SQLite3::Database.open "#{ARGV[0]}.db"
db.execute "drop table if exists source_similarities"
db.execute "create table if not exists source_similarities (target_url string, similar_url string, unique(target_url, similar_url) on conflict replace)"

url_to_converted = {}

lsi = Classifier::LSI.new
sources = db.execute "select url, content_html from source_metadata"
sources.first(200).each do |source|
  puts source[0]
  converted = convert(source[1])
  url_to_converted[source[0]] = converted
  lsi.add_item(converted)
end

sources.first(200).each do |source|
  related_contents = lsi.find_related(convert(source[1]), 5)
  url_to_converted.select { |url,v| source[0] != url && related_contents.include?(v) }.each do |url,_|
    db.execute "insert into source_similarities (target_url, similar_url) values (?, ?)", source[0], url
  end
end
