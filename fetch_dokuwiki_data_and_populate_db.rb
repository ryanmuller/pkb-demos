require "sqlite3"
require "htmlentities"
require "date"
require "json"
require "faraday"
require "yaml"
require "faraday-cookie_jar"
require "nokogiri"

def configuration
  path = File.join File.dirname(__FILE__), "secrets.yml"
  YAML.load_file path
end

domain = ARGV[0].split("/")[0]

login_request = <<eos
<?xml version="1.0"?>
  <methodCall>
    <methodName>dokuwiki.login</methodName>
    <params>
      <param>
        <name>user</name>
        <value>
          <string>ryan</string>
        </value>
      </param>
      <param>
        <name>password</name>
        <value>
          <string>C%x8)duWy6ibnDsr</string>
        </value>
      </param>
    </params>
  </methodCall>
eos

pagelist_request = <<eos
<?xml version="1.0"?>
  <methodCall>
    <methodName>dokuwiki.getPagelist</methodName>
  </methodCall>
eos

conn = Faraday.new(url: "http://#{ARGV[0]}") do |builder|
  builder.use :cookie_jar
  builder.request :url_encoded
  builder.adapter :net_http
end

=begin
<value><struct>\n  <member><name>id</name><value><string>why_list_of_bookmarks_is_a_bad_model_for_a_learning_site</string></value></member>
=end

res = conn.post "lib/exe/xmlrpc.php", login_request
res = conn.post "lib/exe/xmlrpc.php", pagelist_request
File.open("wtf.txt", "w") do |f|
  f.write(res.inspect)
end
raise res.body[0..200]
pages_xml = Nokogiri::XML(res.body)
raise pages_xml.children.children.inspect
raise pages_xml.xpath("member").inspect
page_names = pages_xml.xpath("string").map { |string| string.content }
raise page_names.inspect

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
