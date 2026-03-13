class User
  attr_accessor :name, :age, :role, :email

  def initialize(name, age, role, email)
    @name = name
    @age = age
    @role = role
    @email = email
    @created_at = Time.now.strftime("%F %T")
  end

  def to_s
    "Name: #{@name}, Age: #{@age}, Role: #{@role}, Email: #{@email}, Created At: #{@created_at}"
  end
end

def find_by_attribute(users, attribute, value)
  users.select { |user| user.send(attribute) == value }
end

users = [
  User.new("Alice", 30, "admin", "alice@example.com"),
  User.new("Bob", 25, "user", "bob@example.com"),
  User.new("Charlie", 35, "user", "charlie@example.com"),
  User.new("Dave", 28, "admin", "dave@example.com")
]

admins = find_by_attribute(users, :role, "admin")
puts "Admins:"
admins.each { |admin| puts admin }
