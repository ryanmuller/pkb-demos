require "sqlite3"
require "htmlentities"
require "date"
require "json"
require "faraday"
require "yaml"

def configuration
  path = File.join File.dirname(__FILE__), "secrets.yml"
  YAML.load_file path
end

conn = Faraday.new(url: "https://secure.diigo.com/api/v2/") do |faraday|
  faraday.request :url_encoded
  faraday.adapter :net_http
end
conn.basic_auth(configuration["diigo_username"], configuration["diigo_password"])

bookmarks = []
notes = []
i = 0
loop do
  resp = conn.get "bookmarks", user: ARGV[0], key: configuration["diigo_api_key"], count: 100, start: i
  break if resp.status != 200
  fetched_bookmarks = JSON.parse(resp.body)
  break if fetched_bookmarks == []
  bookmarks += JSON.parse(resp.body)
  notes += bookmarks.flat_map do |b|
    b["annotations"].map do |a|
      { "content" => a["content"], "source_url" => b["url"] }
    end
  end
  i += 100
  raise "oops didn't break" if i > 10000
end
puts "#{bookmarks.size} bookmarks fetched"
puts "#{notes.size} notes fetched"

db = SQLite3::Database.new( "com.diigo.#{ARGV[0]}.db" )
db.execute("create table if not exists notes (content text, source_url string, permalink string primary key, created_at datetime)")
db.execute("create table if not exists sources (url string primary key)")

bookmarks.each do |bookmark|
  begin
    db.execute "insert into sources(url) values (?)", bookmark["url"]
  rescue SQLite3::ConstraintException
  end
end

notes.each do |note|
  db.execute "insert into notes(content, source_url) values (?,?)", note["content"], note["source_url"]
end
