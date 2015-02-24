require "sqlite3"
require "yaml"
require "uri"

def configuration
  path = File.join File.dirname(__FILE__), "secrets.yml"
  YAML.load_file path
end

hostname = URI.parse(configuration["dokuwiki_url"]).host
db = SQLite3::Database.new "#{hostname}.db"
db.execute "create table if not exists notes (content text, source_url string, permalink string primary key, created_at datetime)"
db.execute "create table if not exists sources (url string primary key)"

page_files = File.join configuration["dokuwiki_data_dir"], "pages", "*.txt"
Dir.glob(page_files).each do |f|
  db.execute "insert into notes(content, permalink) values (?,?)",
    File.read(f),
    "#{configuration["dokuwiki_url"]}#{File.basename(f, ".txt")}"
end
