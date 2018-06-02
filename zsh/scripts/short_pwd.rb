pwd = Dir.getwd

unless pwd.start_with?(ENV['HOME'])
  puts pwd
  exit
end

pwd = pwd.sub(ENV['HOME'], '~')
if pwd.size < 20
  puts pwd
  exit
end

items = pwd.split('/')
if items.size < 3
  puts pwd
  exit
end

current_name = items.last
parent_dir = items[0..-2].map do |item|
  item[0]
end.join('/')

puts "#{parent_dir}/#{current_name}"
