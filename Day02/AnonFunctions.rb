def logger
  puts "Hello"
  yield
end

# logger {puts "Hi"}
# logger {puts "hee"}

# logger do
#   p [1,2,3]
# end

# square = Proc.new { |x| x * x }

# puts square.call(5)

square = proc { |x| x ** 2 }

puts square.call(4)

puts logger{square}.call(5)