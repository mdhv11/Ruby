module Test
  def hello
    puts "We are groot!"
  end
end


class Duck
  include Test
  def speak
    puts "Quack"
  end

  private
  def walk
    puts "pitter patter"
  end
end

class Person
  include Test
  def speak
    puts "Hey"
  end
end

class Dog
  
end

def make_speak(object)
  object.speak
end

make_speak(Duck.new)
make_speak(Person.new)
# make_speak(Dog.new)

d1= Duck.new

puts d1.respond_to?(:speak)
puts d1.send(:speak)
puts d1.send(:walk)
puts d1.respond_to?(:walk)
d1.hello


puts Time.now.strftime("%F %T")

def divide_by_zero
  begin
    1 / rand(0..1)
  rescue
    puts "Uh oh! You just divided by zero!"
  end
end

divide_by_zero