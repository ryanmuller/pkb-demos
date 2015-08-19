require 'sinatra'
require 'sinatra/json'
require 'yaml'
require 'json'
require 'faraday'
require 'tumblr_client'
require 'classifier'
require 'readability'
require 'open-uri'
require 'ots'

path = File.join ENV['HOME'], '.tumblr'
configuration = YAML.load_file path

Tumblr.configure do |config|
  Tumblr::Config::VALID_OPTIONS_KEYS.each do |key|
    config.send(:"#{key}=", configuration[key.to_s])
  end
end


def tumblr_data(url)
  client = Tumblr::Client.new
  return client.posts(url)
end

def post_text(tumblr_post)
  tumblr_post["text"] || tumblr_post["caption"] || tumblr_post["body"]
end

def post_url(tumblr_post)
  tumblr_post["source_url"]
end

def post_texts(tumblr_data)
  tumblr_data["posts"].map { |post| post_text(post) }.compact
end

def post_sources(tumblr_data)
end
  tumblr_data["posts"].map { |post| post_url(post) }.compact.uniq

def prismatic_interests(url)
  return "" if url.nil?
  path = File.join File.dirname(__FILE__), 'secrets.yml'
  configuration = YAML.load_file path
  conn = Faraday.new(url: "http://interest-graph.getprismatic.com") do |faraday|
    faraday.request :url_encoded
    faraday.adapter :net_http
  end
  conn.headers = { "X-API-TOKEN" => configuration["prismatic_api_token"] }
  resp = conn.post "/url/topic", url: url
  body = JSON.parse(resp.body.to_s)
  if body["topics"]
    body["topics"].map do |t|
      t["topic"]
    end
  else
    ""
  end
end

def content(url)
  begin
    source = open(url).read
    Readability::Document.new(source).content
  rescue URI::InvalidURIError
    ""
  end
end

def summarize_url(url)
  content = content(url)
  return "" if content.empty?
  article = OTS.parse(content)
  article.summarize(sentences: 3)
end

def keywordize_url(url)
  #content = content(url)
  #return "" if content.empty?
  #article = OTS.parse(content)
  #article.keywords
  # OTS keywords are too extensive
end

get '/:tumblr_url' do |tumblr_url|
  json tumblr_data(tumblr_url)
end

get '/related/:tumblr_url' do |tumblr_url|
  lsi = Classifier::LSI.new
  post_texts = post_texts(tumblr_data(tumblr_url))
  post_texts.each do |t|
    lsi.add_item t
  end
  text_with_related = post_texts.map do |text|
    {
      text: text,
      related: lsi.find_related(text, 3).map { |related_text| "#{related_text[0..64]}..." }
    }
  end
  json text_with_related
end

get '/interests/:tumblr_url' do |tumblr_url|
  url_with_interests = post_sources(tumblr_data(tumblr_url)).map do |url|
    {
      url: url,
      interests: prismatic_interests(url)
    }
  end
  json url_with_interests
end

get '/summaries/:tumblr_url' do |tumblr_url|
  url_with_summary = post_sources(tumblr_data(tumblr_url)).map do |url|
    {
      url: url,
      summary: summarize_url(url)
    }
  end
  json url_with_summary
end
