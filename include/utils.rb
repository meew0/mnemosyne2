def boldify(string)
  "#{2.chr}#{string}#{2.chr}"
end

def comma_list(array)
  return "" if array.empty?
  return boldify(array[0]) if array.size == 1
  return "#{boldify(array[0])} and #{boldify(array[1])}" if array.size == 2

  array[0..-2].map { |e| boldify(e) }.join(", ") + ", and " + boldify(array.last)
end
