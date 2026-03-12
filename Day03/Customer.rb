class Customer
  attr_accessor :customer_id, :name, :age, :phone, :address, :status

  def initialize(customer_id, name, age, phone, address, status = "registered")
    @customer_id = customer_id
    @name = name
    @age = age
    @phone = phone
    @address = address
    @status = status
  end

  def to_s
    "Customer: #{@name}, Age: #{@age}, Phone: #{@phone}, " \
      "Address: #{@address.street}, #{@address.city}, #{@address.state} - #{@address.zip_code}, " \
      "Status: #{@status}"
  end


  # def display
  #   puts "Name is: #@name"
  #   puts "Age is: #@age"
  #   puts "Phone is: #@phone"
  #   puts "City is: #@city"
  # end

  #Getter & Setters
  # def name
  #   @Name
  # end

  # def @Name=(name)
  #   @Name = name
  # end

  # def get_data
  #   puts "Enter your name: "
  #   @name = gets.chomp
  #   puts "Enter your age: "
  #   @age = gets.chomp.to_i
  #   puts "Enter your phone number: "
  #   @phone = gets.chomp
  #   puts "Enter your city: "
  #   @city = gets.chomp
  # end
end

class Address
  attr_accessor :street, :city, :state, :zip_code

  def initialize(street, city, state, zip_code)
    @street = street
    @city = city
    @state = state
    @zip_code = zip_code
  end
end

# c1 = Customer.new("m", 24, "1234567890", "Pune")
# c1.get_data
# c1.display

# puts c1.name = "K"
