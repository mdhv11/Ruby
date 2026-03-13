require 'date'

class Customer
  attr_accessor :customer_id, :name, :dob, :age, :phone, :address, :status, :created_at, :password

  def initialize(customer_id, name, dob, phone, address, password, status = "registered", created_at = nil)
    @customer_id = customer_id
    @name = name
    @dob = dob
    @age = self.class.calculate_age(dob)
    @phone = phone
    @address = address
    @password = password
    @status = status
    @created_at = created_at || Time.now.strftime("%F %T")
  end

  def to_s
    "Customer: #{@name}, DOB: #{@dob}, Phone: #{@phone}, " \
      "Address: #{@address.street}, #{@address.city}, #{@address.state} - #{@address.zip_code}, " \
      "Status: #{@status}"
  end

  def self.calculate_age(dob)
    birth_date = Date.parse(dob)
    today = Date.today
    age = today.year - birth_date.year
    birthday_passed = today.month > birth_date.month || (today.month == birth_date.month && today.day >= birth_date.day)
    age -= 1 unless birthday_passed
    age
  rescue Date::Error
    nil
  end

  # def display
  #   puts "Name is: #@name"
  #   puts "DOB is: #@dob"
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

  def to_h
    {
      street: @street,
      city: @city,
      state: @state,
      zip_code: @zip_code
    }
  end

  def blank?
    [@street, @city, @state, @zip_code].all? { |value| value.to_s.strip.empty? }
  end

  def to_s
    return "Not available" if blank?

    "#{@street}, #{@city}, #{@state} - #{@zip_code}"
  end
end

# c1 = Customer.new("m", 24, "1234567890", "Pune")
# c1.get_data
# c1.display

# puts c1.name = "K"
