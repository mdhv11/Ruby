require_relative 'Bank'
require_relative 'Customer'

class BankSystem
  def initialize
    @customers = {}
    @banks = {}
    @accounts = {}
    @transactions = {}
    @loans = {}
  end

  def start
    loop do
      puts "\n=== Bank Management System ==="
      puts "1. Admin"
      puts "2. Customer"
      puts "3. Exit"

      print "Choose an option: "
      choice = gets.chomp.to_i

      case choice
      when 1 then admin_menu
      when 2 then customer_menu
      when 3
        puts "Exiting..."
        break
      else
        puts "Invalid choice."
      end
    end
  end

  private

  def admin_menu
    puts "\n--- Admin Panel ---"
    puts "1. Add a new Bank"
    puts "2. Create Account"
    puts "3. Approve Loan"
    puts "4. View Account Details"
    puts "5. View Transactions"
    print "Choose an option: "

    case gets.chomp.to_i
    when 1 then add_bank
    when 2 then create_account
    when 3
      print "Enter loan ID to approve: "
      approve_loan(gets.chomp.to_i)
    when 4
      print "Enter account ID to view details: "
      show_account_details(gets.chomp.to_i)
    when 5
      print "Enter account ID to view transactions: "
      show_transactions(gets.chomp.to_i)
    else
      puts "Invalid choice."
    end
  end

  def customer_menu
    puts "\n--- Customer Panel ---"
    puts "1. View Account Details"
    puts "2. Deposit"
    puts "3. Withdraw"
    puts "4. Transfer Amount"
    puts "5. Get Loan"
    puts "6. View Loan Details"
    print "Choose an option: "

    case gets.chomp.to_i
    when 1
      print "Enter your account ID to view details: "
      show_account_details(gets.chomp.to_i)
    when 2
      print "Enter account ID to deposit: "
      deposit(gets.chomp.to_i)
    when 3
      print "Enter account ID to withdraw: "
      withdraw(gets.chomp.to_i)
    when 4
      print "Enter sender account ID: "
      sender_id = gets.chomp.to_i
      print "Enter receiver account ID: "
      receiver_id = gets.chomp.to_i
      transfer_amount(sender_id, receiver_id)
    when 5 then get_loan
    when 6
      print "Enter your customer ID to view loan details: "
      show_loan_details(gets.chomp.to_i)
    else
      puts "Invalid choice."
    end
  end

  def get_valid_input(prompt, regex, error_msg, attempts = 3)
    attempts.times do |i|
      puts prompt
      input = gets.chomp
      return input if input.match?(regex)
      puts "#{error_msg} #{attempts - 1 - i} attempts left."
    end
    nil
  end

  def valid_amount?(amount)
    if amount > 0
      true
    else
      puts "Invalid amount. Must be greater than zero."
      false
    end
  end

  def valid_account?(acc_id)
    if @accounts.key?(acc_id)
      true
    else
      puts "Account not found."
      false
    end
  end

  def valid_customer?(customer_id)
    if @customers.key?(customer_id)
      true
    else
      puts "Customer not found."
      false
    end
  end

  def add_bank
    puts "Enter bank name:"
    bank_name = gets.chomp
    puts "Enter interest rate:"
    rate = gets.chomp.to_f
    bank_id = (@banks.keys.max || 0) + 1

    bank = Bank::Bank.new(bank_id, bank_name, rate)
    @banks[bank_id] = bank

    puts "Bank added successfully with ID: #{bank_id}"
  end

  def create_account
    if @banks.empty?
      return puts "No banks available. Please ask an admin to add a bank first."
    end

    puts "Available Banks:"
    @banks.each { |id, b| puts "ID: #{id} - Name: #{b.bank_name}" }
    print "Enter Bank ID: "
    bank_id = gets.chomp.to_i
    return puts("Invalid Bank ID.") unless @banks.key?(bank_id)

    name = get_valid_input("Enter customer name:", /^(?=.{2,30}$)[A-Za-z]+(?:\s[A-Za-z]+)*$/, "Invalid name.")
    return puts("Failed to create account.") unless name

    age_str = get_valid_input("Enter customer age (18-120):", /^\d+$/, "Invalid age.")
    return puts("Failed to create account.") unless age_str

    age = age_str.to_i
    return puts("Age must be between 18 and 120.") unless age.between?(18, 120)

    phone = get_valid_input("Enter customer phone (10 digits):", /^\d{10}$/, "Invalid phone number.")
    return puts("Failed to create account.") unless phone

    puts "Enter your city:"
    city = gets.chomp

    acc_type_choice = get_valid_input("Select account type: 1. Savings  2. Current", /^[12]$/, "Invalid choice.")
    return puts("Failed to create account.") unless acc_type_choice
    acc_type = acc_type_choice == "1" ? "Savings" : "Current"

    puts "Enter initial deposit amount:"
    balance = gets.chomp.to_f
    return unless valid_amount?(balance)

    customer_id = (@customers.keys.max || 0) + 1
    acc_id = (@accounts.keys.max || 0) + 1

    customer = Customer.new(customer_id, name, age, phone, city)
    @customers[customer_id] = customer

    if acc_type == "Savings"
      account = Bank::SavingsAccount.new(bank_id, acc_id, customer_id, balance)
    else
      account = Bank::CurrentAccount.new(bank_id, acc_id, customer_id, balance)
    end
    @accounts[acc_id] = account

    puts "Account created successfully! Account ID: #{acc_id}, Customer ID: #{customer_id}"
  end

  def deposit(acc_id)
    return unless valid_account?(acc_id)
    acc = @accounts[acc_id]

    puts "Enter the amount to deposit:"
    amount = gets.chomp.to_f
    return unless valid_amount?(amount)

    acc.deposit(amount)

    transaction_id = (@transactions.keys.max || 0) + 1
    @transactions[transaction_id] = Bank::Transactions.new(acc_id, "deposit", amount)

    puts "Transaction successful! Current balance: #{acc.balance}"
  end

  def withdraw(acc_id)
    return unless valid_account?(acc_id)
    acc = @accounts[acc_id]

    puts "Enter the amount to withdraw:"
    amount = gets.chomp.to_f
    return unless valid_amount?(amount)

    if acc.withdraw(amount)
      transaction_id = (@transactions.keys.max || 0) + 1
      @transactions[transaction_id] = Bank::Transactions.new(acc_id, "withdrawal", amount)
      puts "Transaction successful! Current balance: #{acc.balance}"
    else
      puts "Insufficient balance."
    end
  end

  def transfer_amount(sender_id, receiver_id)
    return unless valid_account?(sender_id) && valid_account?(receiver_id)

    if sender_id == receiver_id
      return puts "Cannot transfer to the same account."
    end

    sender_acc = @accounts[sender_id]
    receiver_acc = @accounts[receiver_id]

    puts "Enter the amount to transfer:"
    amount = gets.chomp.to_f
    return unless valid_amount?(amount)

    if sender_acc.withdraw(amount)
      receiver_acc.deposit(amount)

      t_id1 = (@transactions.keys.max || 0) + 1
      @transactions[t_id1] = Bank::Transactions.new(sender_id, "withdrawal", amount)

      t_id2 = t_id1 + 1
      @transactions[t_id2] = Bank::Transactions.new(receiver_id, "deposit", amount)

      puts "Transfer successful!"
    else
      puts "Insufficient balance."
    end
  end

  def get_loan
    puts "Enter your customer id:"
    customer_id = gets.chomp.to_i
    return unless valid_customer?(customer_id)

    puts "Enter your account id to link loan:"
    acc_id = gets.chomp.to_i
    return unless valid_account?(acc_id)

    puts "Enter the principal amount:"
    principal = gets.chomp.to_f
    return unless valid_amount?(principal)

    rate = 10.0

    puts "Enter tenure in months:"
    tenure = gets.chomp.to_i
    return puts("Invalid tenure.") if tenure <= 0

    emi_value = Bank::Loans.calculate_emi(principal, rate, tenure)
    loan_id = (@loans.keys.max || 0) + 1

    loan = Bank::Loans.new(customer_id, acc_id, principal, rate, tenure, emi_value, "pending")
    @loans[loan_id] = loan

    puts "Loan request submitted. Loan ID: #{loan_id}, Estimated EMI: #{emi_value}"
  end

  def approve_loan(loan_id)
    loan = @loans[loan_id]
    return puts("Loan not found.") if loan.nil?

    if loan.status != "pending"
      return puts "Loan is not in pending status."
    end

    loan.status = "approved"
    puts "Loan #{loan_id} approved successfully!"
  end

  def show_loan_details(customer_id)
    found = false
    @loans.each do |loan_id, loan|
      if loan.customer_id == customer_id
        puts "Loan ID: #{loan_id} | Principal: #{loan.principal} | Rate: #{loan.rate}% | Tenure: #{loan.tenure}m | EMI: #{loan.emi} | Status: #{loan.status}"
        found = true
      end
    end
    puts "No loans found for this customer." unless found
  end

  def show_account_details(acc_id)
    acc = @accounts[acc_id]
    return puts("Account not found.") if acc.nil?

    customer = @customers[acc.customer_id]

    puts "\n--- Account Details ---"
    puts "Account ID: #{acc_id}"
    puts "Customer: #{customer.name}"
    puts "Account Type: #{acc.acc_type}"
    puts "Balance: #{acc.balance}"
    puts "-----------------------"
  end

  def show_transactions(acc_id)
    return unless valid_account?(acc_id)

    found = false
    puts "\n--- Transactions for Account #{acc_id} ---"

    @transactions.each do |id, txn|
      if txn.acc_id == acc_id
        puts "[#{txn.timestamp}] #{txn.type.capitalize}: #{txn.amount}"
        found = true
      end
    end

    puts "No transactions found." unless found
    puts "-----------------------------------"
  end
end

if __FILE__ == $0
  system = BankSystem.new
  system.start
end