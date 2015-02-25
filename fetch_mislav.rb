require "./fetch_site"

class MislavArticleScraper < SourceScraper
  element "header a/@href" => :url, with: lambda { |href| href.to_s =~ /^\// ? "http://mislav.uniqpath.com/blog#{href}" : href.to_s }
end

class MislavScraper < SourcesScraper
  elements "article" => :sources, with: MislavArticleScraper
end

FetchSite.fetch_site_and_populate_db("http://mislav.uniqpath.com/blog", MislavScraper)
