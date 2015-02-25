require "open-uri"
require "simple-rss"
require "htmlentities"
require "./populate_db"

class FetchRSS
  def self.fetch_rss_and_populate_db(feed_url, options={})
    {
      db_name: nil,
      description_is_note: false,
      skip_source_content: false
    }.merge options

    rss = SimpleRSS.parse open(feed_url)
    coder = HTMLEntities.new
    db = PopulateDB.new(options[:db_name] || coder.decode(rss.feed.title))
    rss.items.each do |item|
      if options[:description_is_note]
        db.insert :notes, content: content_html(item), source_url: item.link, permalink: item.guid
      end
      db.insert :sources, url: item.link
      unless options[:skip_source_content]
        db.insert :source_metadata, content_html: content_html(item), url: item.link
      end
    end
  end

  def self.content_html(item)
    coder = HTMLEntities.new
    coder.decode(item.description.force_encoding("utf-8"))
  end
end
