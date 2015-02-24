require "classifier"
require "sqlite3"

db = SQLite3::Database.open "#{ARGV[0]}.db"
db.execute "create table if not exists note_similarities (target_url string, similar_url string, unique(target_url, similar_url) on conflict replace)"

lsi = Classifier::LSI.new
notes = db.execute "select content, permalink from notes"
notes.each do |note|
  puts note[1].split("/")[-1]
  lsi.add_item(note[0]) { |content|
    content.downcase
      .gsub(/<\/?[^>]*>/, "") # html tags
      .gsub(/\[\[([^\]]*)\]\]/, "\\1") # wiki inner links
      .gsub(/\[([^\]]*)\]\([^)]*\)/, "\\1") # markdown links
      .gsub("h\d\.", "") # wiki headings
      .gsub(/https?:\/\/\S*/, "") # random links
      .gsub(/~~[^~]*~~/, "") # embed codes
      .gsub(/{{[^}]*}}/, "") # more embed codes
      .gsub(/[^a-zA-Z0-9\-\s]/, "")
  }
end

notes.each do |note|
  related_contents = lsi.find_related(note[0], 5)
  notes.select { |other_note| related_contents.include? other_note[0] }.each do |similar_note|
    db.execute "insert into note_similarities (target_url, similar_url) values (?, ?)", note[1], similar_note[1]
  end
end
