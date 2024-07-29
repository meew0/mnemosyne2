# :[^ ]+!~RX14@[^ ]+ PRIVMSG [^ ]+ :([^\-].*Mnemosyne.*|Mnemosyne.*)

ANSWERS = [
  "yes",
  "most definitely yes",
  "I'm sure",
  "probably yes",
  "likely",
  "no",
  "no..",
  "most definitely no",
  "I see what you did there",
  "..",
  "wat",
  "hweh",
  "absolutely",
  "definitely"
]

puts "#{ctx.user.nick}, #{ANSWERS.sample}."
