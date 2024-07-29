# :[^ ]+ PRIVMSG [^ ]+ :.*
require 'csv'
require './include/tell.rb'

PRIVATE_LIMIT = 4
TIME_FORMAT = "%F %T"

entries = collect_entries(ctx)
unless entries.empty?
  puts "#{ctx.user.nick}, you have #{IRC_BOLD}#{entries.size}#{IRC_BOLD} new message#{entries.size == 1 ? "" : "s"}:"
  entries.sort_by(&:first).each_with_index do |e, i|
    timestamp, source_nick, source_channel, message = e
    puts "Sending #{IRC_BOLD}#{entries.size - PRIVATE_LIMIT}#{IRC_BOLD} further messages privately." if i == PRIVATE_LIMIT
    if i >= 15
      # Taile
      sleep 1
    end
    msg = "#{timestamp.strftime(TIME_FORMAT)} in #{source_channel} - #{IRC_BOLD}#{source_nick}#{IRC_BOLD}: #{message}"
    if i < PRIVATE_LIMIT
      puts msg
    else
      ctx.user.send_message(msg)
    end
  end
end
