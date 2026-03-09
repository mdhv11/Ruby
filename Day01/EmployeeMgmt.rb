$employees = {
  1 => { name: "Sam", age: 25, email: "s@s.com", role: "SDE" },
  2 => { name: "Tony", age: 32, email: "t@t.com", role: "SDE" }
}

def add_employee!()
  puts "Enter employee ID:"
  id = gets.chomp.to_i

  if $employees.include?(id)
    return puts "Employee with given id already exists."
  end

  puts "Enter employee name:"
  name = gets.chomp
  puts "Enter employee age:"
  age = gets.chomp.to_i
  puts "Enter employee email:"
  email = gets.chomp
  puts "Enter employee role:"
  role = gets.chomp
  $employees[id] = { name: name, age: age, email: email, role: role }
end

def read_employee_details(id)
  puts $employees[id]
end

def view_employees
  if $employees.empty?
    puts "No employees found."
  else
    $employees.each do |id, info|
      puts "ID: #{id} | Name: #{info[:name]} | Age: #{info[:age]} | Email: #{info[:email]} | Role: #{info[:role]}"
    end
  end
end

def delete_emp(id)
  if $employees.delete(id)
    puts "Employee removed successfully!"
  else
    puts "Employee not found"
  end
end

def update_emp(id)
  emp = $employees[id]

  if emp
    puts "Updating Employee ID: #{id} (Press Enter to keep current value)"

    print "Name [#{emp[:name]}]: "
    name = gets.chomp
    emp[:name] = name unless name.empty?

    print "Age [#{emp[:age]}]: "
    age = gets.chomp
    emp[:age] = age.to_i unless age.empty?

    print "Email [#{emp[:email]}]: "
    email = gets.chomp
    emp[:email] = email unless email.empty?

    print "Role [#{emp[:role]}]: "
    role = gets.chomp
    emp[:role] = role unless role.empty?

    puts "Employee updated successfully!"
  else
    puts "Error: Employee with ID #{id} not found."
  end
end


loop do
  puts "Employee Management System"
  puts "1. Add employee"
  puts "2. View details of all employees"
  puts "3. View detail of particular employee"
  puts "4. Update employee"
  puts "5. Delete employee"
  puts "6. Exit"

  print "Choose an option: "
  choice = gets.chomp.to_i

  case choice
  when 1
    add_employee!()
  when 2
    view_employees()
  when 3
    puts "Enter the id of the employee: "
    id = gets.chomp.to_i
    read_employee_details(id)
  when 4
    puts "Enter the id of the employee you want to update: "
    id = gets.chomp.to_i
    update_emp(id)
  when 5
    puts "Enter the id of the employee you want to remove: "
    id = gets.chomp.to_i
    delete_emp(id)
  when 6
    puts "Exiting..."
    break
  else
    puts "Invalid option"
  end
end

