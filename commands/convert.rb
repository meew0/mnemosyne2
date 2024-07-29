require 'java'

*head, tail = ARGV[2..-1].join(' ').split(" to ")
head = head.join(' ')

tail, head = head, tail if head.empty?

# smh
#result, status = Open3.capture2e('/usr/bin/units', '-t', head, tail)
#puts result

process = java.lang.ProcessBuilder.new(['/usr/bin/units', '-t', head, tail]).redirect_error_stream(true).start
stream = java.io.BufferedReader.new(java.io.InputStreamReader.new(process.input_stream))
line = nil
puts line until (line = stream.read_line).nil?
