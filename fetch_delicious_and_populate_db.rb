require "./fetch_rss"

username = ARGV[0]
tags = ARGV[1]
format = "rss"
db_name = "delicious.com_#{username}"
feed_url = "http://feeds.delicious.com/v2/#{format}/#{username}#{"/#{tags}" if tags}?count=100"

FetchRSS.fetch_rss_and_populate_db feed_url, db_name: db_name, description_is_note: true, skip_source_content: true
