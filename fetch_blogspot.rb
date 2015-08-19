require "./fetch_site"

module FetchBlogspot
  class Scraper
    def initialize(options={})
      options = {
        month_element: "ul.archive-list a",
        permalink_element: "a[@title='permanent link']"
      }.merge(options)

      archive_class = Class.new(Nibbler) do
        elements "#{options[:month_element]}/@href" => :month_links
      end

      month_class = Class.new(Nibbler) do
        elements "#{options[:permalink_element]}/@href" => :post_links
      end

      FetchBlogspot.const_set("Archive", archive_class)
      FetchBlogspot.const_set("Month", month_class)
    end

    def fetch_and_populate(url, db)
      Archive.parse(open(url)).month_links.each do |month_link|
        Month.parse(open(month_link)).post_links.each do |post_link|
          db.insert :sources, url: post_link
        end
      end
    end
  end
end

#FetchSite.fetch_site_and_populate_db(ARGV[0], FetchBlogspot::Scraper.new)
#slatestarcodex_scraper = FetchBlogspot::Scraper.new(month_element: "#archives-2 a",
#                                                    permalink_element: ".pjgm-postmeta a[@rel='bookmark']")
#FetchSite.fetch_site_and_populate_db("http://slatestarcodex.com/", slatestarcodex_scraper)

psychsci_scraper = FetchBlogspot::Scraper.new(month_element: "ul ul .post-count-link",
                                              permalink_element: ".post-title a")
FetchSite.fetch_site_and_populate_db("http://psychsciencenotes.blogspot.com/", psychsci_scraper)
