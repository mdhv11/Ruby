$customers = {
  1 => { name: "Tom", age: 24, phone: "9876543210", city: "Pune" },
  2 => { name: "Jerry", age: 25, phone: "9123456780", city: "Mumbai" }
}
$accounts = {
  101 => { customer_id: 1, balance: 5000, acc_type: "Savings" },
  102 => { customer_id: 2, balance: 12000, acc_type: "Current" }
}
$transactions = {
  1 => { account_id: 101, type: "deposit", amount: 2000 },
  2 => { account_id: 101, type: "withdrawal", amount: 500 }
}
$loans = {
  1 => { customer_id: 1, principal: 50000, rate: 10, tenure: 36, EMI: 1613, status: "active" },
  2 => { customer_id: 2, principal: 100000, rate: 10, tenure: 24, EMI: 4614, status: "approved" }
  3 => { customer_id: 1, principal: 200000, rate: 10, tenure: 60, EMI: 4248, status: "pending" }
}

def valid_account?(acc_id)
  if !$accounts.key?(acc_id)
    puts "Account not found."
    return false
  end
  true
end

def valid_customer?(customer_id)
  if !$customers.key?(customer_id)
    puts "Customer not found."
    return false
  end
  true
end

def valid_amount?(amount)
  if amount <= 0
    puts "Amount must be greater than 0."
    return false
  end
  true
end

def create_account
  customer_id = ($customers.keys.max || 0) + 1
  acc_id = ($accounts.keys.max || 0) + 1

  puts "Enter customer name:"
  name = gets.chomp
  puts "Enter customer age:"
  age = gets.chomp.to_i
  phone = nil
  3.times do |i|
    puts "Enter customer phone:"
    input = gets.chomp

    if input.match?(/^\d{10}$/)
      phone = input
      break
    else
      puts "Invalid phone number. #{2-i} attempts left"
    end
  end

  return puts("Failed to create account.") if phone.nil?

  puts "Enter your city:"
  city = gets.chomp
  acc_type = nil
  3.times do |i|
    puts "Select account type: 1. Savings 2. Current"
    choice = gets.chomp.to_i

    case choice
    when 1
      acc_type = "Savings"
      break
    when 2
      acc_type = "Current"
      break
    else
      puts "Invalid choice. #{2-i} attempts left"
    end
  end

  return puts("Failed to create account.") if acc_type.nil?

  puts "Enter initial deposit amount:"
  balance = gets.chomp.to_f
  return unless valid_amount?(balance)

  $customers[customer_id] = {
    name: name,
    age: age,
    phone: phone,
    city: city
  }

  $accounts[acc_id] = {
    customer_id: customer_id,
    balance: balance,
    acc_type: acc_type
  }

  puts "Account created successfully!"
  puts "Account ID: #{acc_id}"
end

def withdraw(acc_id)
  return unless valid_account?(acc_id)

  acc = $accounts[acc_id]
  puts "Enter the amount to withdraw:"
  amount = gets.chomp.to_f
  return unless valid_amount?(amount)

  if amount > acc[:balance]
    puts "Insufficient balance."
    return
  end

  acc[:balance] -= amount
  transaction_id = ($transactions.keys.max || 0) + 1
  $transactions[transaction_id] = {account_id: acc_id, type: "withdrawal", amount: amount}

  puts "Transaction successful!"
  puts "Current balance: #{acc[:balance]}"
end

def deposit(acc_id)
  return unless valid_account?(acc_id)

  acc = $accounts[acc_id]

  puts "Enter the amount to deposit:"
  amount = gets.chomp.to_f

  return unless valid_amount?(amount)

  acc[:balance] += amount

  transaction_id = ($transactions.keys.max || 0) + 1
  $transactions[transaction_id] = {account_id: acc_id, type: "deposit", amount: amount}

  puts "Transaction successful!"
  puts "Current balance: #{acc[:balance]}"
end

def transfer_amount(sender_id, receiver_id)
  return unless valid_account?(sender_id)
  return unless valid_account?(receiver_id)

  if sender_id == receiver_id
    puts "Cannot transfer to the same account."
    return
  end

  sender_acc = $accounts[sender_id]
  receiver_acc = $accounts[receiver_id]

  puts "Enter the amount to transfer:"
  amount = gets.chomp.to_f

  return unless valid_amount?(amount)

  if amount > sender_acc[:balance]
    puts "Insufficient balance."
    return
  end

  sender_acc[:balance] -= amount
  receiver_acc[:balance] += amount

  transaction_id = ($transactions.keys.max || 0) + 1
  $transactions[transaction_id] = {account_id: sender_id, type: "withdrawal", amount: amount}

  transaction_id = ($transactions.keys.max || 0) + 1
  $transactions[transaction_id] = {account_id: receiver_id, type: "deposit", amount: amount}

  puts "Transfer successful!"
end

$emi = lambda do |principal, rate, months|
  monthly_rate = rate / (12 * 100.0)

  emi_value = principal * monthly_rate * (1 + monthly_rate)**months / ((1 + monthly_rate)**months - 1)

  emi_value
end

def get_loan
  loan_id = ($loans.keys.max || 0) + 1

  puts "Enter your customer id:"
  customer_id = gets.chomp.to_i

  return unless valid_customer?(customer_id)

  puts "Enter the principal amount:"
  principal = gets.chomp.to_f

  return unless valid_amount?(principal)

  rate = 10

  puts "Enter tenure in months:"
  tenure = gets.chomp.to_i

  if tenure <= 0
    puts "Invalid tenure."
    return
  end

  emi_value = $emi.call(principal, rate, tenure).round(2)

  $loans[loan_id] = {
    customer_id: customer_id,
    principal: principal,
    rate: rate,
    tenure: tenure,
    EMI: emi_value,
    status: "pending"
  }

  puts "Loan request submitted."
end

def approve_loan(loan_id)
  loan = $loans[loan_id]

  if loan.nil?
    puts "Loan not found."
    return
  end

  if loan[:status] != "pending"
    puts "Loan is not in pending status."
    return
  end

  loan[:status] = "approved"
  puts "Loan approved successfully!"
end

def show_loan_details(customer_id)
  $loans.each do |loan_id, loan|
    if loan[:customer_id] == customer_id
      puts "Loan ID: #{loan_id}"
      puts "Principal: #{loan[:principal]}"
      puts "Rate: #{loan[:rate]}"
      puts "Tenure: #{loan[:tenure]}"
      puts "EMI: #{loan[:EMI]}"
      puts "Status: #{loan[:status]}"
      puts "----------------------"
    end
  end
end

def show_account_details(acc_id)
  acc = $accounts[acc_id]

  if acc.nil?
    puts "Account not found."
    return
  end

  customer = $customers[acc[:customer_id]]

  puts "Account ID: #{acc_id}"
  puts "Customer: #{customer[:name]}"
  puts "Account Type: #{acc[:acc_type]}"
  puts "Balance: #{acc[:balance]}"
end

def show_transactions(acc_id)
  return unless valid_account?(acc_id)

  found = false

  $transactions.each do |id, txn|
    if txn[:account_id] == acc_id
      puts "#{txn[:type]} : #{txn[:amount]}"
      found = true
    end
  end

  puts "No transactions found." unless found
end

loop do
  puts "Bank Management System"
  puts "1. Admin"
  puts "2. Customer"
  puts "3. Exit"

  print "Choose an option: "
  choice = gets.chomp.to_i

  case choice
  when 1
    puts "Admin Panel"
    puts "1. Create Account"
    puts "2. Approve Loan"
    puts "3. View Account Details"
    puts "4. View Transactions"

    print "Choose an option: "
    admin_choice = gets.chomp.to_i

    case admin_choice
    when 1
      create_account
    when 2
      puts "Enter loan ID to approve:"
      loan_id = gets.chomp.to_i
      approve_loan(loan_id)
    when 3
      puts "Enter account ID to view details:"
      acc_id = gets.chomp.to_i
      show_account_details(acc_id)
    when 4
      puts "Enter account ID to view transactions:"
      acc_id = gets.chomp.to_i
      show_transactions(acc_id)
    else
      puts "Invalid choice."
    end

  when 2
    puts "Customer Panel"
    puts "1. Deposit"
    puts "2. Withdraw"
    puts "3. Transfer Amount"
    puts "4. Get Loan"
    puts "5. View Loan Details"

    print "Choose an option: "
    customer_choice = gets.chomp.to_i

    case customer_choice
    when 1
      puts "Enter account ID to deposit:"
      acc_id = gets.chomp.to_i
      deposit(acc_id)
    when 2
      puts "Enter account ID to withdraw:"
      acc_id = gets.chomp.to_i
      withdraw(acc_id)
    when 3
      puts "Enter sender account ID:"
      sender_id = gets.chomp.to_i
      puts "Enter receiver account ID:"
      receiver_id = gets.chomp.to_i
      transfer_amount(sender_id, receiver_id)
    when 4
      get_loan
    when 5
      puts "Enter your customer ID to view loan details:"
      customer_id = gets.chomp.to_i
      show_loan_details(customer_id)
    else
      puts "Invalid choice."
    end

  when 3
    puts "Exiting..."
    break

  else
    puts "Invalid choice."
  end
end
