require "faraday"
require "yaml"
require "sqlite3"
require "json"
require "optparse"
require "open-uri"
require "openssl"
require "readability"
require "zlib"

def configuration
  path = File.join File.dirname(__FILE__), "secrets.yml"
  YAML.load_file path
end

# returns a comma separated list of topics according to the Interest Graph API
def prismatic_interests(url)
  return "" if url.nil? or url.empty?
  conn = Faraday.new(url: "http://interest-graph.getprismatic.com") do |faraday|
    faraday.request :url_encoded
    faraday.adapter :net_http
  end
  conn.headers = { "X-API-TOKEN" => configuration["prismatic_api_token"] }
  begin
    resp = conn.post "/url/topic", url: url
    body = JSON.parse(resp.body)
    (body["topics"] || []).map { |t| t["topic"] }.join ","
  rescue Faraday::TimeoutError, JSON::ParserError, Faraday::ConnectionFailed
    ""
  end
end

# returns a string of the HTML-formatted content in a URL
def content_html(url)
  begin
    source = open(url).read
    Readability::Document.new(source).content
  rescue URI::InvalidURIError, RuntimeError, OpenURI::HTTPError, SocketError, OpenSSL::SSL::SSLError, Errno::ETIMEDOUT, Zlib::BufError
    ""
  end
end

options = {}
OptionParser.new do |opts|
  opts.on("--rebuild", "Rebuild source metadata table") do |r|
    options[:rebuild] = r
  end
end.parse!

db = SQLite3::Database.open "#{ARGV[0]}.db"
if options[:rebuild]
  db.execute "drop table if exists source_metadata"
end

db.execute "create table if not exists source_metadata (url string primary key, interests string, content_html text)"
db.execute "create table if not exists interest_sources (interest string, url string, unique(interest,url) on conflict ignore)"

db.execute("select url from sources").map { |s| s[0] }.each do |url|
  begin
    db.execute "insert into source_metadata (url) values (?)", url
  rescue SQLite3::ConstraintException
  end
end

# update interests
#db.execute("select url from source_metadata where interests is null").map { |s| s[0] }.each do |url|
#  db.execute "update source_metadata set interests=? where url=?", prismatic_interests(url), url
#end
#
## update interest sources
#db.execute("select url, interests from source_metadata").each do |source|
#  source[1].split(",").each do |interest|
#    db.execute "insert into interest_sources(interest, url) values (?,?)", interest, source[0]
#  end
#end

# update content
db.execute("select url from source_metadata where content_html is null").map { |s| s[0] }.each do |url|
  db.execute "update source_metadata set content_html=? where url=?", content_html(url), url
end
