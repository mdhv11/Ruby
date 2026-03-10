# puts "Enter a number"
# choice = gets.chomp.to_i

# case choice
# when 1..5
#   puts "U are red"
# when 6..10
#   puts "U are green"
# when 11..15
#   puts "U are blue"
# else
#   puts "U are rainbow"
# end


puts "Enter the battery percentage"
choice = gets.chomp.to_i

case choice
when 1..20
  puts "Charge ur device"
when 21..50
  puts "The device will last for few hrs"
when 51..75
  puts "U can run a marathon"
when 76..100
  puts "The device will last a day"
else
  puts "Invalid battery charge percentage"
end