require "./fetch_site"

class TLMArticleScraper < SourceScraper
  element "a/@href" => :url, with: lambda { |href| "http://tenderlovemaking.com#{href}" }
end

class TLMScraper < SourcesScraper
  elements "h2 + ul li" => :sources, with: TLMArticleScraper
end

FetchSite.fetch_site_and_populate_db("http://tenderlovemaking.com/archives.html", TLMScraper)
