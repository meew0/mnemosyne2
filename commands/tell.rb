require 'csv'
require 'securerandom'
require './include/tell.rb'

data = ARGV[1..-1]
exit unless data.size > 2

# targets = data[1].split(',').map(&.split(':'))
targets = data[1]
parsed = parse_targets(targets)
content = [targets, (Time.now.to_f * 1000).to_i, ctx.user.nick, ctx.channel.private? ? "private chat" : ctx.channel.name, data[2..-1].join(' ')]
ctx.pctx.put('tell', SecureRandom.uuid, content.to_csv)

IRC_BOLD = 2.chr
puts "I'll remember to tell #{IRC_BOLD}#{fancy_format(parsed)}#{IRC_BOLD} that as soon as possible."
