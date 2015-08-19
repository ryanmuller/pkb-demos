require "./fetch_site"

module FetchSlateStarCodex
  class Link < SourceScraper
    element "a/@href" => :url
  end

  class Scraper < SourcesScraper
    elements ".sya_postcontent" => :sources, with: Link
  end
end

FetchSite.fetch_site_and_populate_db("http://slatestarcodex.com/archives/", FetchSlateStarCodex::Scraper)
