# :[^ ]+ PRIVMSG [^ ]+ :.*(?:https?://)?(?:www\.)?(?:youtube\.com/(?:[^/\n\s]+/\S+/|(?:watch|e(?:mbed)?)\S*?[?&]v=)|youtu\.be/)([a-zA-Z0-9\-_]{11}).*

require 'net/http'
require 'json'
require 'uri'
require 'date'

API_KEY = File.read('youtube_api_key.txt')
IRC_BOLD = 2.chr

# Function to extract all video IDs from YouTube URLs in the source string
def extract_video_ids(source)
  youtube_regex = %r{
    (?:https?:\/\/)?(?:www\.)?
    (?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:watch|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)
    ([a-zA-Z0-9\-_]{11})
  }x
  source.scan(youtube_regex).flatten
end

# Function to make API request and retrieve video details
def fetch_video_details(video_id)
  base_url = "https://www.googleapis.com/youtube/v3/videos"
  params = {
    part: 'snippet,statistics',
    id: video_id,
    key: API_KEY
  }
  uri = URI(base_url)
  uri.query = URI.encode_www_form(params)
  response = Net::HTTP.get(uri)
  JSON.parse(response)
end

# Function to display video details
def display_video_details(video_details)
  if video_details['items'] && video_details['items'].any?
    video = video_details['items'].first
    snippet = video['snippet']
    statistics = video['statistics']
    
    puts "#{IRC_BOLD}#{snippet['title']}#{IRC_BOLD} by #{IRC_BOLD}#{snippet['channelTitle']}#{IRC_BOLD}, uploaded on #{IRC_BOLD}#{DateTime.parse(snippet['publishedAt']).strftime("%F %T")}#{IRC_BOLD} (#{IRC_BOLD}#{statistics['viewCount']}#{IRC_BOLD} view#{statistics['viewCount'].to_i == 1 ? '' : 's'}, #{IRC_BOLD}#{statistics['likeCount']}#{IRC_BOLD} like#{statistics['likeCount'].to_i == 1 ? '' : 's'}, #{IRC_BOLD}#{statistics['commentCount']}#{IRC_BOLD} comment#{statistics['commentCount'].to_i == 1 ? '' : 's'})"
  end
end

# Extract all video IDs from the source string
video_ids = extract_video_ids(ARGV[2..-1].join(' '))

if video_ids.any?
  video_ids.each do |video_id|
    video_details = fetch_video_details(video_id)
    display_video_details(video_details)
  end
end
