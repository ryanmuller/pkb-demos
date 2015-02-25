require "open-uri"
require "uri"
require "securerandom"
require "ostruct"
require "nibbler"
require "./populate_db"

class FetchSite
  def self.fetch_site_and_populate_db(url, scraper, options={})
    db = PopulateDB.new(options[:db_name] || URI.parse(url).host)
    scraper.fetch_and_populate url, db
  end
end

class SourcesScraper < Nibbler
  def self.fetch_and_populate(url, db)
    parsed = parse open(url)
    parsed.sources.each do |source|
      db.insert :sources, url: source.url

      if source.content_html
        db.insert :source_metadata, content_html: source.content_html, url: source.url
      end
    end
  end
end

class SourceScraper < Nibbler
  private

  def default_source
    # required: url
    OpenStruct.new(
      content_html: nil
    )
  end

  def method_missing(name, *args, &block)
    default_source.send name
  end
end

class NotesScraper < Nibbler
  def self.fetch_and_populate(url, db)
    parsed = parse open(url)
    parsed.notes.each do |note|
      db.insert :notes, content: note.content, source_url: note.source_url, permalink: note.permalink, created_at: note.created_at

      if note.source_url
        db.insert :sources, url: note.source_url
      end
    end
  end
end

class NoteScraper < Nibbler
  private

  def default_note
    # required: content
    OpenStruct.new(
     source_url: nil,
     permalink: SecureRandom.uuid,
     created_at: Time.now
    )
  end

  def method_missing(name)
    default_note.send name
  end
end
