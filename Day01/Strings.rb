#strings

s = "Hello World"

t = "Ruby is fun"

u = s + " " + t
v = s.clone
v.concat(" ", t)
puts u
puts v

s += "!" + " " + t
puts s

puts s.capitalize
puts s.downcase
puts t.downcase

puts "Hi".upcase

puts s.length
puts t.length

puts s.reverse

puts s.include?("World")
puts s.include?("world")

puts t.replace("Ruby is awesome")
puts t.gsub("awesome", "fun")

w = s.split(" ")
# puts w[0]
# puts w[1]
puts w

puts s.match?(/Hello/)
puts s.match?(/hello/)

text = "   hello   "
puts text.strip

age = "25"
puts age.to_i

puts "3.14".to_f

puts "Ruby! " * 3

name = "Madhav"

puts name[0]
puts name[2]
puts name[0..2]

puts s.start_with?("Hello")
puts s.end_with?("World")

t = 55