require "faraday"
require "yaml"
require "sqlite3"
require "json"
require "optparse"
require "open-uri"
require "readability"
require "./stash"

def top_terms(doc_id, n=5)
  semantics = ObjectStash.load "./#{ARGV[0]}-docs.stash"
  unless semantics[doc_id].nil?
    semantics[doc_id].sort.reverse[0..n].map { |weigh_word| weigh_word[1] }
  else
    []
  end
end

def configuration
  path = File.join File.dirname(__FILE__), "secrets.yml"
  YAML.load_file path
end

options = {}
OptionParser.new do |opts|
  opts.on("--rebuild", "Rebuild source metadata table") do |r|
    options[:rebuild] = r
  end
end.parse!

db = SQLite3::Database.open "#{ARGV[0]}.db"
if options[:rebuild]
  db.execute "drop table if exists note_metadata"
end

db.execute "create table if not exists note_metadata (url string primary key, terms string)"

db.execute("select permalink from notes").map { |s| s[0] }.each do |url|
  begin
    db.execute "insert into note_metadata (url) values (?)", url
  rescue SQLite3::ConstraintException
  end
end

# update terms
db.execute("select url from note_metadata").map { |s| s[0] }.each do |url|
  db.execute "update note_metadata set terms = ? where url = ?", top_terms(url).join(","), url
end
