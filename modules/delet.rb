# :[^ ]+ PRIVMSG [^ ]+ :delet .*

IRC_BOLD = 2.chr

full_argument = (ARGV[3..-1] * ' ')
delet_pos = full_argument.index(':delet ')
argument = full_argument[(delet_pos + 7)..-1]
dc = argument.downcase
count = ctx.get(dc) || 0
count += 1
ctx.put(dc, count)
puts "#{IRC_BOLD}#{argument}#{IRC_BOLD} has been deleted #{IRC_BOLD}#{count}#{IRC_BOLD} time#{count == 1 ? '' : 's'}."
