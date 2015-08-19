require "./fetch_site"

class PRLinkScraper < SourceScraper
  element "a/@href" => :url, with: lambda { |href| href.to_s =~ /^\// ? "https://practicingruby.com#{href}" : href.to_s }
end

class PRScraper < SourcesScraper
  elements "td.article" => :sources, with: PRLinkScraper
end

FetchSite.fetch_site_and_populate_db("https://practicingruby.com", PRScraper)
