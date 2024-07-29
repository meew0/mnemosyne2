require 'csv'
require './include/tell.rb'
require './include/utils.rb'

entries = collect_entries(ctx)

names = entries.sort_by(&:first).map { |e| e[1] }.uniq
puts "Messages by #{comma_list(names)} were dropped."
