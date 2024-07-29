TimeEntry = Struct.new(:hours, :minutes, :negative)

begin
  Time.now.localtime(ARGV[2])
  ctx.pctx.put("time", ctx.user.nick, ARGV[2])
  IRC_BOLD = 2.chr
  puts "Set #{IRC_BOLD}#{ctx.user.nick}#{IRC_BOLD}'s desired time offset."
rescue ArgumentError
  puts "Invalid time format! Try something like +01:00"
end
