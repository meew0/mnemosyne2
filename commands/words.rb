num = ARGV[2..-1].join(' ').to_i

if !num.nil? && num > 0
  if num <= 10
    MML = File.read('mml.txt').lines
    selection = MML.sample(num).map(&:strip)
    puts selection.join(", ")
  else
    puts "Sorry, only at most 10 words can be selected at once."
  end
else
  puts "Invalid number!"
end
