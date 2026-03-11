class Customer
  attr_accessor :customer_id, :name, :age, :phone, :city

  def initialize(customer_id, name, age, phone, city)
    @customer_id = customer_id
    @name = name
    @age = age
    @phone = phone
    @city = city
  end

  def display
    puts "Name is: #@name"
    puts "Age is: #@age"
    puts "Phone is: #@phone"
    puts "City is: #@city"
  end

  #Getter & Setters
  # def name
  #   @Name
  # end

  # def @Name=(name)
  #   @Name = name
  # end

  def get_data
    puts "Enter your name: "
    @name = gets.chomp
    puts "Enter your age: "
    @age = gets.chomp.to_i
    puts "Enter your phone number: "
    @phone = gets.chomp
    puts "Enter your city: "
    @city = gets.chomp
  end
end

# c1 = Customer.new("m", 24, "1234567890", "Pune")
# c1.get_data
# c1.display

# puts c1.name = "K"