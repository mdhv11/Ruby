module Animals
  class Dog
    def speak
      puts "woof woof!"
    end
  end

  class Cat
    def speak
      puts "meow meow"
    end
  end
end

module Robot
  class Dog
    def speak
      puts "beep beep"
    end
  end
end

animal_dog = Animals::Dog.new
robot_dog = Robot::Dog.new

animal_dog.speak
robot_dog.speak

puts "----------------------------------"

module Speakable
  def greet
    puts "Hello from #{self.class}"
  end
end

class Person
  include Speakable
end

class Robots
  extend Speakable
end

Person.new.greet
Robots.greet


puts "----------------------------------"

module Loggable
  def process_data
    puts "Logging: Starting data processing"
    super
    puts "Logging: Finished data processing"
  end
end

class DataProcessor
  prepend Loggable

  def process_data
    puts "Processing the actual data"
  end
end

class SimpleProcessor
  include Loggable

  def process_data
    puts "Simple processing"
    super rescue puts "No super method found"
  end
end

puts "With prepend:"
DataProcessor.new.process_data

puts "\nWith include:"
SimpleProcessor.new.process_data