require "sqlite3"
require "yaml"
require "./populate_db"

def configuration
  path = File.join File.dirname(__FILE__), "secrets.yml"
  YAML.load_file path
end

db_out = PopulateDB.new(File.join(configuration["data_dir"], "pkb.db"))

ARGV.each do |db_in_file|
  db_in = PopulateDB.new(db_in_file)
  db_in.notes.each do |note|
    db_out.insert :notes,
      content: note[:content],
      source_url: note[:source_url],
      permalink: note[:permalink],
      created_at: note[:created_at]
  end

  db_in.sources.each do |source|
    db_out.insert :sources, url: source[:url]
    if source[:content_html] and !source[:content_html].empty?
      db_out.insert :source_metadata,
        url: source[:url],
        content_html: source[:content_html]
    end
  end
end
