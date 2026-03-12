require_relative 'Bank'
require_relative 'Customer'
require 'json'

class BankSystem
  LOAN_RATE = 10.0.freeze
  DATA_FILE = File.join(__dir__, 'bank_data.json').freeze

  def initialize
    @customers = {}
    @banks = {}
    @accounts = {}
    @transactions = {}
    @loans = {}
    load_data
  end

  def save_data
    data = {
      customers: @customers.transform_values do |customer|
        {
          customer_id: customer.customer_id,
          name: customer.name,
          age: customer.age,
          phone: customer.phone,
          address: customer.address,
          status: customer.status
        }
      end,
      banks: @banks.transform_values do |bank|
        {
          bank_id: bank.bank_id,
          bank_name: bank.bank_name,
          rate: bank.rate
        }
      end,
      accounts: @accounts.transform_values do |account|
        {
          bank_id: account.bank_id,
          acc_id: account.acc_id,
          customer_id: account.customer_id,
          balance: account.balance,
          acc_type: account.acc_type,
          status: account.status
        }
      end,
      transactions: @transactions.transform_values do |transaction|
        {
          acc_id: transaction.acc_id,
          type: transaction.type,
          amount: transaction.amount,
          timestamp: transaction.timestamp
        }
      end,
      loans: @loans.transform_values do |loan|
        {
          customer_id: loan.customer_id,
          acc_id: loan.acc_id,
          principal: loan.principal,
          rate: loan.rate,
          tenure: loan.tenure,
          emi: loan.emi,
          amount_paid: loan.amount_paid,
          amount_remaining: loan.amount_remaining,
          status: loan.status
        }
      end
    }

    File.write(DATA_FILE, JSON.pretty_generate(data))
    puts "Data saved to #{DATA_FILE}"
  rescue StandardError => e
    puts "Failed to save data: #{e.message}"
  end

  def load_data
    return unless File.exist?(DATA_FILE)
    return if File.zero?(DATA_FILE)

    data = JSON.parse(File.read(DATA_FILE))

    @customers = build_customers(data['customers'])
    @banks = build_banks(data['banks'])
    @accounts = build_accounts(data['accounts'])
    @transactions = build_transactions(data['transactions'])
    @loans = build_loans(data['loans'])
    sync_customer_statuses
  rescue JSON::ParserError => e
    puts "Failed to load data: invalid JSON in #{DATA_FILE} (#{e.message})"
  rescue StandardError => e
    puts "Failed to load data: #{e.message}"
  end

  def start
    loop do
      puts "\n=== Bank Management System ==="
      puts "1. Admin"
      puts "2. Register Customer"
      puts "3. Customer Login"
      puts "4. Exit"

      begin
        case prompt_integer("Choose an option:")
        when 1 then admin_menu
        when 2 then register_customer
        when 3
          customer_id, acc_id = customer_login
          customer_menu(customer_id, acc_id)
        when 4
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

  private

  def build_customers(customer_data)
    return {} unless customer_data

    customer_data.each_with_object({}) do |(id, customer), customers|
      customers[id.to_i] = Customer.new(
        customer['customer_id'],
        customer['name'],
        customer['age'],
        customer['phone'],
        Address.new(
          customer['address']['street'],
          customer['address']['city'],
          customer['address']['state'],
          customer['address']['zip_code']
        ),
        customer['status'] || 'registered'
      )
    end
  end

  def build_banks(bank_data)
    return {} unless bank_data

    bank_data.each_with_object({}) do |(id, bank), banks|
      banks[id.to_i] = BankService::Bank.new(
        bank['bank_id'],
        bank['bank_name'],
        bank['rate']
      )
    end
  end

  def build_accounts(account_data)
    return {} unless account_data

    account_data.each_with_object({}) do |(id, account), accounts|
      accounts[id.to_i] =
        if account['acc_type'] == 'Savings'
          BankService::SavingsAccount.new(account['bank_id'], account['acc_id'], account['customer_id'], account['balance'], account['status'] || 'active')
        else
          BankService::CurrentAccount.new(account['bank_id'], account['acc_id'], account['customer_id'], account['balance'], account['status'] || 'active')
        end
    end
  end

  def build_transactions(transaction_data)
    return {} unless transaction_data

    transaction_data.each_with_object({}) do |(id, transaction), transactions|
      txn = BankService::Transactions.new(
        transaction['acc_id'],
        transaction['type'],
        transaction['amount']
      )
      txn.timestamp = transaction['timestamp']
      transactions[id.to_i] = txn
    end
  end

  def build_loans(loan_data)
    return {} unless loan_data

    loan_data.each_with_object({}) do |(id, loan), loans|
      loan_record = BankService::Loans.new(
        id.to_i,
        loan['customer_id'],
        loan['acc_id'],
        loan['principal'],
        loan['rate'],
        loan['tenure'],
        loan['emi'],
        loan['status']
      )
      loan_record.amount_paid = loan['amount_paid']
      loan_record.amount_remaining = loan['amount_remaining']
      loans[id.to_i] = loan_record
    end
  end

  def admin_menu
    loop do
      puts "\n--- Admin Panel ---"
      puts "1. Add a new Bank"
      puts "2. View Registered Customers"
      puts "3. Create Account"
      puts "4. Approve Loan"
      puts "5. View Account Details"
      puts "6. View Transactions"
      puts "7. View Top 5 Transactions"
      puts "8. View Customer with Highest Balance"
      puts "9. View Customers with No Loans"
      puts "10. Approve Loan Closure Requests"
      puts "11. Back to Main Menu"

      begin
        case prompt_integer("Choose an option:")
        when 1 then add_bank
        when 2 then show_registered_customers
        when 3 then create_account
        when 4 then approve_loan(prompt_with_attempts { prompt_integer("Enter loan ID to approve:") })
        when 5 then show_account_details(prompt_with_attempts { prompt_integer("Enter account ID to view details:") })
        when 6 then show_transactions(prompt_with_attempts { prompt_integer("Enter account ID to view transactions:") })
        when 7 then show_top_transactions
        when 8 then show_customer_with_highest_balance
        when 9 then show_customers_with_no_loans
        when 10 then approve_loan_closure(prompt_with_attempts { prompt_integer("Enter loan ID to approve closure:") })
        when 11 then break
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
    if account.status == "deactivated"
      puts "This account is deactivated. Please contact the bank for more information."
      return
    else
      loop do
        puts "\n--- Customer Panel ---"
        puts "Welcome #{customer.name}! You are logged into account #{acc_id} (#{account.acc_type})"
        puts "------------------------"
        puts "1. View Account Details"
        puts "2. Deposit"
        puts "3. Withdraw"
        puts "4. Transfer Amount"
        puts "5. Get Loan"
        puts "6. View Loan Details"
        puts "7. Pay EMI"
        puts "8. Request Loan Closure"
        puts "9. Deactivate Account"
        puts "10. Back to Main Menu"

        begin
          case prompt_integer("Choose an option:")
          when 1 then show_account_details(acc_id)
          when 2 then deposit(acc_id)
          when 3 then withdraw(acc_id)
          when 4 then transfer_amount(acc_id, prompt_with_attempts { prompt_integer("Enter receiver account ID:") })
          when 5 then get_loan(customer_id, acc_id)
          when 6 then show_loan_details(customer_id)
          when 7 then pay_emi(customer_id, acc_id, prompt_with_attempts { prompt_integer("Enter loan ID to pay EMI:") })
          when 8 then request_loan_closure(customer_id, acc_id, prompt_with_attempts { prompt_integer("Enter loan ID to request closure:") })
          when 9 then deactivate_account(acc_id)
          when 10 then break
          else
            raise ArgumentError, "Invalid choice."
          end
        rescue StandardError => e
          puts "Error: #{e.message}"
        end

        account = fetch_account(acc_id)
      end
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
    raise ArgumentError, "Amount must be greater than zero." unless amount > 0

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
    account = @accounts[acc_id]
    raise RuntimeError, "Account not found." if account.nil?

    account
  end

  def fetch_customer(customer_id)
    customer = @customers[customer_id]
    raise RuntimeError, "Customer not found." if customer.nil?

    customer
  end

  def fetch_loan(loan_id)
    loan = @loans[loan_id]
    raise RuntimeError, "Loan not found." if loan.nil?

    loan
  end

  def fetch_customer_account(customer_id, acc_id)
    customer = fetch_customer(customer_id)
    account = fetch_account(acc_id)
    raise RuntimeError, "This account does not belong to the given customer." unless account.customer_id == customer_id

    [customer, account]
  end

  def sync_customer_statuses
    @customers.each_key { |customer_id| refresh_customer_status(customer_id) }
  end

  def refresh_customer_status(customer_id)
    customer = @customers[customer_id]
    return if customer.nil?

    customer_accounts = @accounts.values.select { |account| account.customer_id == customer_id }

    customer.status =
      if customer_accounts.empty?
        "registered"
      elsif customer_accounts.any? { |account| account.status != "deactivated" }
        "active"
      else
        "inactive"
      end
  end

  def customer_login
    customer_id = prompt_with_attempts { prompt_integer("Enter your customer ID:") }
    acc_id = prompt_with_attempts { prompt_integer("Enter your account ID:") }
    customer, account = fetch_customer_account(customer_id, acc_id)
    raise RuntimeError, "Customer is inactive. Please contact the bank." if customer.status == "inactive"
    raise RuntimeError, "This account is deactivated. Please contact the bank." if account.status == "deactivated"

    puts "Welcome #{customer.name}!"
    puts "Logged into account #{acc_id} (#{account.acc_type})"

    [customer_id, acc_id]
  end

  def add_bank
    bank_name = prompt_with_attempts { prompt("Enter bank name:") }
    rate = prompt_with_attempts { prompt_amount("Enter interest rate:") }
    bank_id = (@banks.keys.max || 0) + 1

    bank = BankService::Bank.new(bank_id, bank_name, rate)
    @banks[bank_id] = bank

    save_data
    puts "Bank added successfully with ID: #{bank_id}"
  end

  def register_customer
    name = get_valid_input("Enter customer name:", /^(?=.{2,30}$)[A-Za-z]+(?:\s[A-Za-z]+)*$/, "Invalid name.")
    return puts("Failed to register customer.") unless name

    age_str = get_valid_input("Enter customer age (18-120):", /^\d+$/, "Invalid age.")
    return puts("Failed to register customer.") unless age_str

    age = age_str.to_i
    return puts("Age must be between 18 and 120.") unless age.between?(18, 120)

    phone = get_valid_input("Enter customer phone (10 digits):", /^\d{10}$/, "Invalid phone number.")
    return puts("Failed to register customer.") unless phone

    address = Address.new(
      prompt_with_attempts { prompt("Enter your street:") },
      prompt_with_attempts { prompt("Enter your city:") },
      prompt_with_attempts { prompt("Enter your state:") },
      prompt_with_attempts { prompt("Enter your zip code:") }
    )

    customer_id = (@customers.keys.max || 0) + 1

    customer = Customer.new(customer_id, name, age, phone, address, "registered")
    @customers[customer_id] = customer

    save_data
    puts "Customer registered successfully! Customer ID: #{customer_id}"
  end

  def create_account
    if @banks.empty?
      return puts "No banks available. Please ask an admin to add a bank first."
    end

    if @customers.empty?
      return puts "No registered customers found. Ask the customer to register first."
    end

    customer_id = prompt_with_attempts { prompt_integer("Enter customer ID:") }
    customer = fetch_customer(customer_id)

    puts "Creating account for #{customer.name} (Customer ID: #{customer.customer_id})"
    puts "Available Banks:"
    @banks.each { |id, b| puts "ID: #{id} - Name: #{b.bank_name}" }

    bank_id = prompt_with_attempts { prompt_integer("Enter Bank ID:") }
    return puts("Invalid Bank ID.") unless @banks.key?(bank_id)

    acc_type_choice = get_valid_input("Select account type: 1. Savings  2. Current", /^[12]$/, "Invalid choice.")
    return puts("Failed to create account.") unless acc_type_choice

    acc_type = acc_type_choice == "1" ? "Savings" : "Current"
    balance = prompt_with_attempts { prompt_amount("Enter initial deposit amount:") }
    acc_id = (@accounts.keys.max || 0) + 1

    if acc_type == "Savings"
      account = BankService::SavingsAccount.new(bank_id, acc_id, customer_id, balance, "active")
    else
      account = BankService::CurrentAccount.new(bank_id, acc_id, customer_id, balance, "active")
    end

    @accounts[acc_id] = account
    refresh_customer_status(customer_id)
    save_data
    puts "Account created successfully! Account ID: #{acc_id}, Customer ID: #{customer_id}"
  end

  def deposit(acc_id)
    acc = fetch_account(acc_id)
    amount = prompt_with_attempts { prompt_amount("Enter the amount to deposit:") }

    acc.deposit(amount)

    transaction_id = (@transactions.keys.max || 0) + 1
    @transactions[transaction_id] = BankService::Transactions.new(acc_id, "deposit", amount)

    save_data
    puts "Transaction successful! Current balance: #{acc.balance}"
  end

  def withdraw(acc_id)
    acc = fetch_account(acc_id)
    amount = prompt_with_attempts { prompt_amount("Enter the amount to withdraw:") }

    if acc.withdraw(amount)
      transaction_id = (@transactions.keys.max || 0) + 1
      @transactions[transaction_id] = BankService::Transactions.new(acc_id, "withdrawal", amount)
      save_data
      puts "Transaction successful! Current balance: #{acc.balance}"
    else
      puts "Insufficient balance."
    end
  end

  def transfer_amount(sender_id, receiver_id)
    sender_acc = fetch_account(sender_id)
    receiver_acc = fetch_account(receiver_id)
    return puts "Cannot transfer to the same account." if sender_id == receiver_id

    amount = prompt_with_attempts { prompt_amount("Enter the amount to transfer:") }

    if sender_acc.withdraw(amount)
      receiver_acc.deposit(amount)

      t_id1 = (@transactions.keys.max || 0) + 1
      @transactions[t_id1] = BankService::Transactions.new(sender_id, "account_transfer", amount)

      t_id2 = t_id1 + 1
      @transactions[t_id2] = BankService::Transactions.new(receiver_id, "account_transfer", amount)

      save_data
      puts "Transfer successful!"
      puts "Sender balance: #{sender_acc.balance}"
    else
      puts "Insufficient balance."
    end
  end

  def get_loan(customer_id, acc_id)
    fetch_customer_account(customer_id, acc_id)
    principal = prompt_with_attempts { prompt_amount("Enter the principal amount:") }

    rate = LOAN_RATE

    tenure = prompt_with_attempts { prompt_integer("Enter tenure in months:") }
    return puts("Invalid tenure.") if tenure <= 0

    emi_value = BankService::Loans.calculate_emi(principal, rate, tenure)
    loan_id = (@loans.keys.max || 0) + 1

    loan = BankService::Loans.new(loan_id, customer_id, acc_id, principal, rate, tenure, emi_value, "pending")
    @loans[loan_id] = loan

    save_data
    puts "Loan request submitted. Loan ID: #{loan_id}, Estimated EMI: #{emi_value}"
  end

  def approve_loan(loan_id)
    loan = fetch_loan(loan_id)

    if loan.status != "pending"
      return puts "Loan is not in pending status."
    end

    loan.status = "approved"
    save_data
    puts "Loan #{loan_id} approved successfully!"
  end

  def show_loan_details(customer_id)
    fetch_customer(customer_id)
    customer_loans = @loans.values.select { |loan| loan.customer_id == customer_id }

    if customer_loans.empty?
      puts "No loans found for this customer."
    else
      customer_loans.each do |loan|
        puts "Principal: #{loan.principal} | Rate: #{loan.rate}% | Tenure: #{loan.tenure}m | EMI: #{loan.emi}"
        puts "Amount Paid: #{loan.amount_paid.round(2)} | Amount Remaining: #{loan.amount_remaining.round(2)} | Status: #{loan.status}"
        puts "----------------------"
      end
    end
  end

  def pay_emi(customer_id, acc_id, loan_id)
    loan = fetch_loan(loan_id)
    return puts "You can only pay EMI for your own loan." unless loan.customer_id == customer_id && loan.acc_id == acc_id
    return puts "Only approved loans can be paid." unless loan.status == "approved"

    acc = fetch_account(acc_id)
    if acc.withdraw(loan.emi)
      transaction_id = (@transactions.keys.max || 0) + 1
      @transactions[transaction_id] = BankService::Transactions.new(loan.acc_id, "emi_payment", loan.emi)
      loan.amount_paid += loan.emi
      total_payable = (loan.emi * loan.tenure).round(2)
      loan.amount_remaining = [total_payable - loan.amount_paid, 0.0].max.round(2)

      loan.status = "closed" if loan.amount_paid >= total_payable
      save_data

      puts "EMI payment successful! Remaining account balance: #{acc.balance}"
      puts "Total loan paid: #{loan.amount_paid.round(2)} / #{total_payable}"

      if loan.status == "closed"
        puts "Congratulations! Your loan is fully paid and now closed."
      end
    else
      puts "Insufficient account balance to pay EMI."
    end
  end

  def request_loan_closure(customer_id, acc_id, loan_id)
    loan = fetch_loan(loan_id)
    return puts "You can only request closure for your own loan." unless loan.customer_id == customer_id && loan.acc_id == acc_id
    if loan.status != "approved"
      return puts "Only approved loans can be closed."
    end
    if loan.amount_remaining > 0
      return puts "Cannot request closure. Pay the remaining amount of: #{loan.amount_remaining.round(2)}"
    end
    loan.status = "closure_requested"
    save_data
    puts "Loan closure requested for Loan ID: #{loan_id}"
  end

  def approve_loan_closure(loan_id)
    loan = fetch_loan(loan_id)
    if loan.status != "closure_requested"
      return puts "No closure request found for this loan."
    end
    loan.status = "closed"
    save_data
    puts "Loan ID: #{loan_id} has been closed successfully!"
  end

  def deactivate_account(acc_id)
    acc = fetch_account(acc_id)
    customer = fetch_customer(acc.customer_id)
    active_loans = @loans.values.find { |loan| loan.acc_id == acc_id && loan.amount_remaining > 0 }
    if active_loans
      return puts "Cannot deactivate account with active loans. Please pay off remaining loan amount: #{active_loans.amount_remaining.round(2)}"
    end
    if acc.balance > 0
      withdraw_amount = acc.balance
      acc.withdraw(withdraw_amount)
      transaction_id = (@transactions.keys.max || 0) + 1
      @transactions[transaction_id] = BankService::Transactions.new(acc_id, "withdrawal", withdraw_amount)
      puts "Withdrew remaining balance of #{withdraw_amount} before deactivation."
    end
    acc.status = "deactivated"
    customer.status = "inactive"
    refresh_customer_status(customer.customer_id)
    save_data
    puts "Account #{acc_id} has been deactivated."
  end

  def show_account_details(acc_id)
    acc = fetch_account(acc_id)

    customer = @customers[acc.customer_id]

    puts "\n--- Account Details ---"
    puts "Account ID: #{acc_id}"
    puts "Customer: #{customer.name}"
    puts "Customer Status: #{customer.status}"
    puts "Address: #{customer.address.street}, #{customer.address.city}, #{customer.address.state} - #{customer.address.zip_code}"
    puts "Account Type: #{acc.acc_type}"
    puts "Balance: #{acc.balance}"
    puts "-----------------------"
  end

  def show_transactions(acc_id)
    fetch_account(acc_id)

    puts "\n--- Transactions for Account #{acc_id} ---"

    account_txns = @transactions.values.select { |txn| txn.acc_id == acc_id }

    if account_txns.empty?
      puts "No transactions found."
    else
      account_txns.each do |txn|
        puts "[#{txn.timestamp}] #{txn.type.capitalize}: #{txn.amount}"
      end
    end

    puts "-----------------------------------"
  end

  def top_transactions
    @transactions.values.sort_by { |t| -t.amount }.first(5)
  end

  def show_top_transactions
    top_transactions.each do |t|
      puts "Account ID: #{t.acc_id} | Type: #{t.type} | Amount: #{t.amount} | Timestamp: #{t.timestamp}"
    end
  end

  def show_customer_with_highest_balance
    account = @accounts.values.max_by { |acc| acc.balance }
    return puts "No accounts available." if account.nil?

    customer = @customers[account.customer_id]
    puts "Customer with highest balance: #{customer.name} (Customer ID: #{customer.customer_id})"
    puts "Account ID: #{account.acc_id} | Balance: #{account.balance}"
  end

  def show_registered_customers
    return puts "No registered customers found." if @customers.empty?

    puts "\n--- Registered Customers ---"
    @customers.values.sort_by(&:customer_id).each do |customer|
      account_count = @accounts.values.count { |account| account.customer_id == customer.customer_id }
      puts "Customer ID: #{customer.customer_id} | Name: #{customer.name} | Status: #{customer.status} | Phone: #{customer.phone} | Address: #{customer.address.street}, #{customer.address.city}, #{customer.address.state} - #{customer.address.zip_code} | Accounts: #{account_count}"
    end
  end

  def show_customers_with_no_loans
    loaned_customers = @loans.values.map(&:customer_id).uniq
    customers = @customers.values.reject { |customer| loaned_customers.include?(customer.customer_id) }

    return puts "All customers have at least one loan." if customers.empty?

    customers.each do |customer|
      puts "Customer ID: #{customer.customer_id} | Name: #{customer.name} | Status: #{customer.status}"
    end
  end

end

system = BankSystem.new
system.start
