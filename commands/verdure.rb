require 'java'
require 'fileutils'
require 'open3'
require 'digest'
require 'json'

IRC_BOLD = 2.chr

ADJECTIVES = %w(lush vibrant serene tranquil flourishing verdant thriving pristine pure peaceful gentle abundant soothing refreshing radiant fresh calm nurturing serene majestic picturesque scenic inviting refreshing blissful lively enchanting bountiful harmonious rejuvenating blooming graceful delicate soft rich bright lush invigorating fragrant beautiful serene charming magical idyllic glorious natural welcoming)
NOUNS = %w(meadow pond grove stream marsh glade forest fen creek lagoon thicket bayou swamp river wetland pool oasis brook estuary glen dell rainforest spring cove jungle bay vale pasture fenland lake waterfall fjord islet bluff reef woodland valley)

NAVIDROME_ACCENTS = { 'À' => 'A', 'Á' => 'A', 'Â' => 'A', 'Ã' => 'A', 'Ä' => 'A', 'Å' => 'A', 'Ă' => 'A', 'Æ' => 'AE', 'Ç' => 'C', 'È' => 'E', 'É' => 'E', 'Ê' => 'E', 'Ë' => 'E', 'Ì' => 'I', 'Í' => 'I', 'Î' => 'I', 'Ï' => 'I', 'Ð' => 'D', 'Ł' => 'L', 'Ñ' => 'N', 'Ò' => 'O', 'Ó' => 'O', 'Ô' => 'O', 'Õ' => 'O', 'Ö' => 'O', 'Ø' => 'O', 'Œ' => 'OE', 'Ř' => 'R', 'Ś' => 'S', 'Ș' => 'S', 'Ş' => 'S', 'Š' => 'S', 'Ț' => 'T', 'Ù' => 'U', 'Ú' => 'U', 'Ü' => 'U', 'Û' => 'U', 'Ý' => 'Y', 'Þ' => 'TH', 'ẞ' => 'SS', 'à' => 'a', 'á' => 'a', 'â' => 'a', 'ã' => 'a', 'ä' => 'a', 'å' => 'a', 'ă' => 'a', 'æ' => 'ae', 'ç' => 'c', 'è' => 'e', 'é' => 'e', 'ê' => 'e', 'ë' => 'e', 'ì' => 'i', 'í' => 'i', 'î' => 'i', 'ï' => 'i', 'ð' => 'd', 'ł' => 'l', 'ñ' => 'n', 'ń' => 'n', 'ò' => 'o', 'ó' => 'o', 'ô' => 'o', 'õ' => 'o', 'ō' => 'o', 'ö' => 'o', 'ø' => 'o', 'œ' => 'oe', 'ř' => 'r', 'ś' => 's', 'ș' => 's', 'ş' => 's', 'š' => 's', 'ț' => 't', 'ù' => 'u', 'ú' => 'u', 'û' => 'u', 'ū' => 'u', 'ü' => 'u', 'ý' => 'y', 'ÿ' => 'y', 'ż' => 'z', 'þ' => 'th', 'ß' => 'ss' }

SOURCE_FOLDER = '/music'
TARGET_FOLDER = '/verdure-library'

v_query = ARGV[2..-1].join(' ')
v_query_clean = v_query.chars.map { |c| NAVIDROME_ACCENTS[c] || c }.join
num_select, tokens = v_query_clean.split(/[[:space:]]+/).partition { |e| e =~ /^#\d+$/ }
clauses = (["full_text LIKE ? ESCAPE '!'"] * tokens.length).join(' AND ')

def sql_escape(str)
  str.gsub('!', '!!').gsub('%', '!%').gsub('_', '!_').gsub('[', '![')
end

connection = java.sql.DriverManager.get_connection('jdbc:sqlite:/navidrome-data/navidrome.db')

# Get count
statement = connection.prepare_statement('SELECT count(*) FROM media_file WHERE ' + clauses + ' ORDER BY id')
tokens.each_with_index do |e, i|
  statement.set_string(i + 1, "%#{sql_escape(e)}%")
end

result_set = statement.execute_query
count = result_set.get_int(1) if result_set.next

# Get actual results
statement = connection.prepare_statement('SELECT path, title, artist, album FROM media_file WHERE ' + clauses + ' ORDER BY id LIMIT 1001')
tokens.each_with_index do |e, i|
  statement.set_string(i + 1, "%#{sql_escape(e)}%")
end

result_set = statement.execute_query
result_data = []
while result_set.next
  result_data << [result_set.get_string('path'), result_set.get_string('title'), result_set.get_string('artist'), result_set.get_string('album')]
end

connection.close

# Reorder results: put full matches at the top
def full_match?(query, e, indices)
  indices.all? { |i| query.include?(e[i]) }
end
v_query_downcase = v_query.downcase

full_title_album, full_title, full_album, full_artist, remainder = [], [], [], [], []
result_data.each do |e|
  match_title, match_artist, match_album = [1, 2, 3].map { |i| v_query_downcase.include?(e[i].downcase) }
  if match_title && match_album
    full_title_album << e
  elsif match_title
    full_title << e
  elsif match_album
    full_album << e
  elsif match_artist
    full_artist << e
  else
    remainder << e
  end
end

result_data = full_title_album + full_title + full_album + full_artist + remainder

# Obtain selected one
unless num_select.empty?
  num_selected = num_select.first
  num = num_selected[1..-1].to_i
  if num.nil? || num < 1 || num > result_data.length
    puts "Could not select result #{num_selected} (#{result_data.length} results found in total)"
    exit
  end
  result_data = [result_data[num - 1]]
end

def stringify_result(result)
  _, title, artist, album = result
  "#{IRC_BOLD}#{artist}#{IRC_BOLD} - #{IRC_BOLD}#{title}#{IRC_BOLD} (album #{IRC_BOLD}#{album}#{IRC_BOLD})"
end

def read_tags(file)
  json, status = Open3.capture2e('ffprobe', '-v', 'quiet', '-print_format', 'json', '-show_entries', 'format_tags=title,artist,album,track:stream_tags=title,artist,album,track', file)

  unless status.success?
    STDERR.puts("[verdure] read_tags failed: #{json}")
    return nil
  end

  data = JSON.parse(json)
  tags_hash = data['format']['tags'] || data['streams'].filter { |e| e.key?('tags') && e['tags'].key?('track') }.first['tags']

  if tags_hash.nil?
    STDERR.puts("[verdure] Could not find tags hash in JSON: #{json}")
    return nil
  end

  {
    album: tags_hash['album'] || tags_hash['ALBUM'],
    artist: tags_hash['artist'] || tags_hash['ARTIST'],
    title: tags_hash['title'] || tags_hash['TITLE'],
  }
end

if result_data.length == 0
  puts "No results found"
elsif result_data.length == 1
  sub_path, r_title, r_artist, r_album = result_data[0]
  file = File.join(SOURCE_FOLDER, sub_path)
  file_tags = read_tags(file)
  if file_tags.nil?
    # Fall back to the tags given by navidrome
    file_tags = {
      album: r_album,
      artist: r_artist,
      title: r_title,
    }
  end

  # Create a RNG seeded from the SHA256 hash of the file path
  rng = Random.new(Digest::SHA256.digest(sub_path).unpack('Q*').reduce(1) { |a, e| (a << 64) + e })

  name = nil

  100.times do
    # Ensure these are sampled in a deterministic order
    parts = []
    parts << ADJECTIVES.sample(random: rng)
    parts << ADJECTIVES.sample(random: rng)
    parts << NOUNS.sample(random: rng)

    name = parts.join('-')
    target_path = File.join(TARGET_FOLDER, name)
    if File.exist?(target_path)
      # File exists, so only overwrite it if it has the same tags, otherwise try again
      target_tags = read_tags(target_path)
      STDERR.puts("[verdure] overwriting existing file #{target_path}")
      break if target_tags == file_tags
    else
      # File does not yet exist, so create it with the current name
      break
    end
  end

  if name.nil?
    STDERR.puts '[verdure] Source file: ' + file
    puts 'Could not generate a suitable filename after 100 tries :('
    exit
  end

  target_filename = File.join(TARGET_FOLDER, name + '.ogg')
  FileUtils.rm(target_filename) if File.exist?(target_filename)
  cover_base_filename = File.join(TARGET_FOLDER, name)

  # Convert to 128k ogg opus
  system('ffmpeg', '-i', file, '-c:a', 'libopus', '-b:a', '128k', target_filename)

  # Check for cover image and copy if it exists
  cover_image = nil
  ['cover.jpg', 'cover.png'].each do |cover|
    cover_path = File.join(File.dirname(file), cover)
    if File.exist?(cover_path)
      cover_image = cover_path
      break
    end
  end

  if cover_image
    FileUtils.cp(cover_image, cover_base_filename)
  end

  puts "#{IRC_BOLD}https://mz.sb/verdure/#{name}#{IRC_BOLD}  ·  #{stringify_result(result_data[0])}"
else
  puts "Ambiguous query, found #{count || (result_data.length == 11 ? '>10' : result_data.length)} results (use `-verdure [...] #2` to select result #2). Showing first #{[3, result_data.length].min}:"
  result_data[0..2].each_with_index do |result, i|
    puts "##{i + 1}: #{stringify_result(result)}"
  end
end
