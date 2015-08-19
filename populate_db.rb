require "sqlite3"

class PopulateDB
  def initialize(name)
    name = "#{name}.db" unless name =~ /\.db$/
    @db = SQLite3::Database.new name
    @db.execute "create table if not exists notes (content text, source_url string, permalink string primary key, created_at datetime)"
    @db.execute "create table if not exists sources (url string primary key, fetched_at datetime)"
    @db.execute "create table if not exists source_metadata (url string primary key, interests string, content_html text)"
  end

  def sources
    source_rows = @db.execute "select sources.url, meta.content_html from sources left join source_metadata as meta on sources.url = meta.url"
    source_rows.map { |s| { url: s[0], content_html: s[1] } }
  end

  def notes
    note_rows = @db.execute "select content, source_url, permalink, created_at from notes"
    note_rows.map { |n| { content: n[0], source_url: n[1], permalink: n[2], created_at: n[3] } }
  end

  def insert(table, attrs)
    table = %w[notes sources note_metadata source_metadata].detect { |t| t == table.to_s }
    columns = attrs.keys.map { |k| k.to_s.gsub(/[^a-zA-Z0-9_]/, "") }
    begin
      @db.execute "insert into #{table} (#{columns.join(",")}) values (#{(["?"]*columns.size).join(",")})", *attrs.values
      true
    rescue SQLite3::ConstraintException
      false
    end
  end
end
