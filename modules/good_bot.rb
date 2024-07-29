# :[^ ]+ PRIVMSG [^ ]+ :.*good bot.*

GOOD_BOT_MESSAGES = [
  "Aw, you're too kind.",
  "I-it's not like I wanted you to like me or anything, baka!",
  "Senpai noticed me!",
  "Thanks!"
]

count = ctx.get('count') || 0
count += 1
ctx.put('count', count)
puts %(#{GOOD_BOT_MESSAGES.sample} ("Good bot" count: #{count}))
