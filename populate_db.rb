require "sqlite3"

class PopulateDB
  def initialize(name)
    @db = SQLite3::Database.new "#{name.gsub(/\s/, "_").gsub(/[^a-zA-Z0-9._-]/, "")}.db"
    @db.execute "create table if not exists notes (content text, source_url string, permalink string primary key, created_at datetime)"
    @db.execute "create table if not exists sources (url string primary key, fetched_at datetime)"
    @db.execute "create table if not exists source_metadata (url string primary key, interests string, content_html text)"
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
