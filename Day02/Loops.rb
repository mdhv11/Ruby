i = 0
loop do
  puts "i is #{i}"
  i += 1
  break if i == 11
end

a = [1,2,3,4,5]

a.each {|i| puts i*2}

for i in 0..10
  puts "#{i*2}"
end

5.times do |number|
  puts "Hi! #{number}"
end

i = 0
while i < 10 do 
  puts "#{i*10}"
  i += 1
end

i = 0
until i >= 10 do
  puts "#{i*5}"
  i += 1
end


2.upto(10) {|num| print "#{num}"}
puts " "
10.downto(2) {|num| print "#{num}"}

