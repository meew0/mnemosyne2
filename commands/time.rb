TIME_FORMAT = "%F %T"
IRC_BOLD = 2.chr
time_target = ARGV[2].nil? ? ctx.user.nick : ARGV[2]

unless ctx.pctx.has('time', time_target)
  puts "That user has not set their desired offset yet!"
  exit
end

time = Time.now.localtime(ctx.pctx.get('time', time_target))
puts "The current time for #{IRC_BOLD}#{time_target}#{IRC_BOLD} is #{time.strftime(TIME_FORMAT)}."
