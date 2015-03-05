require "selenium-webdriver"
require "sqlite3"
require "./fetch_site"

class RYMTrackRatingScraper
  def self.fetch_and_populate(url, db)
    driver = Selenium::WebDriver.for :firefox
    driver.navigate.to url

    loop do
      show_track_rating_divs = driver.find_elements(class: "track_rating_header")
      show_track_rating_divs.each do |div|
        div.click
      end

      album_artists = driver.find_elements(css: ".or_q_albumartist .artist:first-child").map(&:text) # to avoid issues with multi-artist albums, not ideal
      album_titles = driver.find_elements(css: ".or_q_albumartist .album").map(&:text) 
      album_years = driver.find_elements(css: ".or_q_albumartist span.smallgray").map(&:text)
      album_links = driver.find_elements(css: ".or_q_albumartist a.album").map { |a| a[:href] }
      track_rating_tables = driver.find_elements(class: "trackratings")

      track_rating_tables.each_with_index do |table, album_index|
        table_id = table[:id]
        track_titles = driver.find_elements(css: "##{table_id} td:nth-child(2)").map(&:text)
        track_ratings = driver.find_elements(css: "##{table_id} td:nth-child(3) img").map { |img|
          /(\d+)m\.png$/.match(img[:src])[1]
        }
        note_content = "#{album_artists[album_index]} - #{album_titles[album_index]} #{album_years[album_index]}\n"
        track_titles.each_with_index do |track_title, track_index|
          note_content << "- #{track_title}: #{track_ratings[track_index]}\n"
        end
        db.insert :notes, content: note_content, source_url: album_links[album_index], permalink: "#{driver.current_url}##{table_id}"
        db.insert :sources, url: album_links[album_index]
      end

      begin
        driver.find_element(class: "navlinknext").click
      rescue Selenium::WebDriver::Error::NoSuchElementError
        break
      end
    end

    driver.quit
  end

  def self.best_tracks(db_name)
    db = SQLite3::Database.open "#{db_name}.db"
    notes = db.execute "select content from notes"
    notes.each do |note|
      content = note[0]
      next unless content
      artist = content.split(" -")[0].strip
      content.split("\n").each do |line|
        if line =~ /(9|10)$/
          track_title = line.match(/^- (.*): \d+$/)[1]
          puts "#{"**" if line =~ /10$/}#{artist} - #{track_title}"
        end
      end
    end
  end
end

FetchSite.fetch_site_and_populate_db("https://rateyourmusic.com/collection/#{ARGV[0]}/track_ratings", RYMTrackRatingScraper, db_name: "rateyourmusic.com_#{ARGV[0]}_track_ratings")
RYMTrackRatingScraper.best_tracks("rateyourmusic.com_#{ARGV[0]}_track_ratings")
