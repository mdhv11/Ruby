LOAN_RATE = 10.0.freeze

$customers = {
  1 => { name: "Tom", age: 24, phone: "9876543210", city: "Pune" },
  2 => { name: "Jerry", age: 25, phone: "9123456780", city: "Mumbai" }
}
$accounts = {
  1 => { customer_id: 1, balance: 5000, acc_type: "Savings" },
  2 => { customer_id: 2, balance: 12000, acc_type: "Current" }
}
$transactions = {
  1 => { account_id: 1, type: "deposit", amount: 2000, time: "2026-03-15 20:05:12" },
  2 => { account_id: 1, type: "withdrawal", amount: 1000, time: "2026-03-16 10:15:30" },
  3 => { account_id: 2, type: "withdrawal", amount: 500, time: "2026-03-11 18:05:12" }
}
$loans = {
  1 => { customer_id: 1, principal: 50000, rate: 10, tenure: 36, EMI: 1613, status: "approved" },
  2 => { customer_id: 2, principal: 100000, rate: 10, tenure: 24, EMI: 4614, status: "approved" },
  3 => { customer_id: 1, principal: 200000, rate: 10, tenure: 60, EMI: 4248, status: "pending" }
}

def prompt(message)
  print "#{message} "
  input = gets
  raise EOFError, "Input stream closed." if input.nil?

  value = input.chomp.strip
  raise ArgumentError, "Input cannot be empty." if value.empty?

  value
end

def prompt_integer(message)
  Integer(prompt(message))
rescue ArgumentError
  raise ArgumentError, "Please enter a valid integer."
end

def prompt_float(message)
  Float(prompt(message))
rescue ArgumentError
  raise ArgumentError, "Please enter a valid number."
end

def prompt_amount(message)
  amount = prompt_float(message)
  raise ArgumentError, "Amount must be greater than 0." unless amount > 0

  amount
end

def prompt_with_attempts(attempts = 3)
  remaining = attempts

  loop do
    return yield
  rescue StandardError => e
    remaining -= 1
    puts "Error: #{e.message}"
    raise if remaining <= 0
    puts "Attempts left: #{remaining}"
  end
end

def fetch_account(acc_id)
  account = $accounts[acc_id]
  raise RuntimeError, "Account not found." if account.nil?

  account
end

def fetch_customer(customer_id)
  customer = $customers[customer_id]
  raise RuntimeError, "Customer not found." if customer.nil?

  customer
end

def fetch_loan(loan_id)
  loan = $loans[loan_id]
  raise RuntimeError, "Loan not found." if loan.nil?

  loan
end

def fetch_customer_account(customer_id, acc_id)
  customer = fetch_customer(customer_id)
  account = fetch_account(acc_id)
  raise RuntimeError, "This account does not belong to the given customer." unless account[:customer_id] == customer_id

  [customer, account]
end

def next_id(collection)
  (collection.keys.max || 0) + 1
end

def record_transaction(account_id, type, amount)
  transaction_id = next_id($transactions)
  $transactions[transaction_id] = { account_id: account_id, type: type, amount: amount, time: Time.now.strftime("%F %T") }
end

def prompt_name
  value = prompt("Enter customer name:")
  raise ArgumentError, "Name must be 2 to 30 letters." unless value.match?(/^(?=.{2,30}$)[A-Za-z]+(?:\s[A-Za-z]+)*$/)

  value
end

def prompt_age
  age = prompt_integer("Enter customer age (must be 18 or older):")
  raise ArgumentError, "Age must be between 18 and 120." unless age.between?(18, 120)

  age
end

def prompt_phone
  value = prompt("Enter customer phone:")
  raise ArgumentError, "Phone number must be exactly 10 digits." unless value.match?(/^\d{10}$/)

  value
end

def prompt_city
  prompt("Enter your city:")
end

def prompt_account_type
  choice = prompt("Select account type: 1. Savings 2. Current")

  case choice
  when "1" then "Savings"
  when "2" then "Current"
  else
    raise ArgumentError, "Please choose 1 or 2."
  end
end

def create_account
  customer_id = next_id($customers)
  acc_id = next_id($accounts)

  name = prompt_with_attempts { prompt_name }
  age = prompt_with_attempts { prompt_age }
  phone = prompt_with_attempts { prompt_phone }
  city = prompt_with_attempts { prompt_city }
  acc_type = prompt_with_attempts { prompt_account_type }
  balance = prompt_with_attempts { prompt_amount("Enter initial deposit amount:") }

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
  puts "Customer ID: #{customer_id}"
end

def withdraw(acc_id)
  acc = fetch_account(acc_id)
  amount = prompt_with_attempts { prompt_amount("Enter the amount to withdraw:") }
  raise RuntimeError, "Insufficient balance." if amount > acc[:balance]

  acc[:balance] -= amount
  record_transaction(acc_id, "withdrawal", amount)

  puts "Transaction successful!"
  puts "Current balance: #{acc[:balance]}"
end

def deposit(acc_id)
  acc = fetch_account(acc_id)
  amount = prompt_with_attempts { prompt_amount("Enter the amount to deposit:") }

  acc[:balance] += amount
  record_transaction(acc_id, "deposit", amount)

  puts "Transaction successful!"
  puts "Current balance: #{acc[:balance]}"
end

def transfer_amount(sender_id, receiver_id)
  sender_acc = fetch_account(sender_id)
  receiver_acc = fetch_account(receiver_id)
  raise ArgumentError, "Cannot transfer to the same account." if sender_id == receiver_id

  amount = prompt_with_attempts { prompt_amount("Enter the amount to transfer:") }
  raise RuntimeError, "Insufficient balance." if amount > sender_acc[:balance]

  sender_acc[:balance] -= amount
  receiver_acc[:balance] += amount

  record_transaction(sender_id, "withdrawal", amount)
  record_transaction(receiver_id, "deposit", amount)

  puts "Transfer successful!"
  puts "Sender balance: #{sender_acc[:balance]}"
  puts "Receiver balance: #{receiver_acc[:balance]}"
end

$emi = lambda do |principal, rate, months|
  monthly_rate = rate / (12 * 100.0)

  emi_value = principal * monthly_rate * (1 + monthly_rate)**months / ((1 + monthly_rate)**months - 1)

  emi_value
end

def get_loan(customer_id)
  fetch_customer(customer_id)
  loan_id = next_id($loans)
  principal = prompt_with_attempts { prompt_amount("Enter the principal amount:") }

  rate = LOAN_RATE
  tenure = prompt_with_attempts { prompt_integer("Enter tenure in months:") }
  raise ArgumentError, "Tenure must be greater than 0." unless tenure > 0

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
  puts "Loan ID: #{loan_id}"
end

def approve_loan(loan_id)
  loan = fetch_loan(loan_id)
  raise RuntimeError, "Loan is not in pending status." if loan[:status] != "pending"

  loan[:status] = "approved"
  puts "Loan approved successfully!"
end

def show_loan_details(customer_id)
  fetch_customer(customer_id)
  customer_loans = $loans.select { |_, loan| loan[:customer_id] == customer_id }

  if customer_loans.empty?
    puts "No loans found for this customer."
  else
    customer_loans.each do |loan_id, loan|
      puts "----------------------"
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
  acc = fetch_account(acc_id)
  customer = $customers[acc[:customer_id]]

  puts "----------------------"
  puts "Account ID: #{acc_id}"
  puts "Customer: #{customer[:name]}"
  puts "Account Type: #{acc[:acc_type]}"
  puts "Balance: #{acc[:balance]}"
  puts "----------------------"
end

def show_transactions(acc_id)
  fetch_account(acc_id)
  puts "\n--- Transactions for Account #{acc_id} ---"

  account_txns = $transactions.values.select { |txn| txn[:account_id] == acc_id }

  if account_txns.empty?
    puts "No transactions found."
  else
    account_txns.each do |txn|
      puts "[#{txn[:time]}] #{txn[:type].capitalize}: #{txn[:amount]}"
    end
  end
  puts "-----------------------------------"
end

def admin_menu
  loop do
    begin
      puts "----------------------"
      puts "Admin Panel"
      puts "----------------------"
      puts "1. Create Account"
      puts "2. Approve Loan"
      puts "3. View Account Details"
      puts "4. View Transactions"
      puts "5. Back to Main Menu"

      case prompt_integer("Choose an option:")
      when 1
        create_account
      when 2
        loan_id = prompt_with_attempts { prompt_integer("Enter loan ID to approve:") }
        approve_loan(loan_id)
      when 3
        acc_id = prompt_with_attempts { prompt_integer("Enter account ID to view details:") }
        show_account_details(acc_id)
      when 4
        acc_id = prompt_with_attempts { prompt_integer("Enter account ID to view transactions:") }
        show_transactions(acc_id)
      when 5
        break
      else
        raise ArgumentError, "Invalid choice."
      end
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end
end

def customer_menu(customer_id, acc_id)
  customer, account = fetch_customer_account(customer_id, acc_id)

  loop do
    begin
      puts "----------------------"
      puts "Customer Panel"
      puts "Customer: #{customer[:name]}"
      puts "Customer ID: #{customer_id}"
      puts "Account ID: #{acc_id}"
      puts "Account Type: #{account[:acc_type]}"
      puts "----------------------"
      puts "1. View Account Details"
      puts "2. View Transactions"
      puts "3. Deposit"
      puts "4. Withdraw"
      puts "5. Transfer Amount"
      puts "6. Get Loan"
      puts "7. View Loan Details"
      puts "8. Back to Main Menu"

      case prompt_integer("Choose an option:")
      when 1
        show_account_details(acc_id)
      when 2
        show_transactions(acc_id)
      when 3
        deposit(acc_id)
      when 4
        withdraw(acc_id)
      when 5
        receiver_id = prompt_with_attempts { prompt_integer("Enter receiver account ID:") }
        transfer_amount(acc_id, receiver_id)
      when 6
        get_loan(customer_id)
      when 7
        show_loan_details(customer_id)
      when 8
        break
      else
        raise ArgumentError, "Invalid choice."
      end

      account = fetch_account(acc_id)
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end
end

def customer_login
  customer_id = prompt_with_attempts { prompt_integer("Enter your customer ID:") }
  acc_id = prompt_with_attempts { prompt_integer("Enter your account ID:") }
  customer, account = fetch_customer_account(customer_id, acc_id)

  puts "Welcome #{customer[:name]}!"
  puts "Logged into account #{acc_id} (#{account[:acc_type]})"

  [customer_id, acc_id]
end

begin
  loop do
    begin
      puts "----------------------"
      puts "Bank Management System"
      puts "1. Admin"
      puts "2. Customer"
      puts "3. Exit"
      puts "----------------------"

      case prompt_integer("Choose an option:")
      when 1
        admin_menu
      when 2
        customer_id, acc_id = customer_login
        customer_menu(customer_id, acc_id)
      when 3
        puts "Exiting..."
        break
      else
        raise ArgumentError, "Invalid choice."
      end
    rescue StandardError => e
      puts "Error: #{e.message}"
    end
  end
rescue Interrupt
  puts "\nExiting safely..."
rescue EOFError => e
  puts "\n#{e.message}"
end
