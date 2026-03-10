lambda = -> { return 1 }
puts "lambda res: #{lambda.call}"

proc = proc{ return 2 }
puts "Proc res: #{proc.call}"

puts a = 10%0