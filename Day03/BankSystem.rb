require_relative 'Bank'
require_relative 'Customer'
require 'json'
require 'date'
require 'rainbow'
require 'tty-prompt'

class BankSystem
  DATA_FILE = File.join(__dir__, 'bank_data.json').freeze

  def initialize
    @prompt = TTY::Prompt.new(interrupt: :exit)
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
          dob: customer.dob,
          age: customer.age,
          phone: customer.phone,
          address: customer.address.to_h,
          password: customer.password,
          status: customer.status,
          created_at: customer.created_at
        }
      end,
      banks: @banks.transform_values do |bank|
        {
          bank_id: bank.bank_id,
          bank_name: bank.bank_name,
          loan_rate: bank.loan_rate
        }
      end,
      accounts: @accounts.transform_values do |account|
        {
          bank_id: account.bank_id,
          acc_id: account.acc_id,
          customer_id: account.customer_id,
          interest_rate: account.interest_rate,
          balance: account.balance,
          acc_type: account.acc_type,
          status: account.status,
          created_at: account.created_at
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
          loan_id: loan.loan_id,
          customer_id: loan.customer_id,
          acc_id: loan.acc_id,
          principal: loan.principal,
          loan_rate: loan.loan_rate,
          tenure: loan.tenure,
          installments_paid: loan.installments_paid,
          installments_remaining: loan.installments_remaining,
          emi: loan.emi,
          amount_paid: loan.amount_paid,
          amount_remaining: loan.amount_remaining,
          status: loan.status,
          loan_start_date: loan.loan_start_date,
          loan_end_date: loan.loan_end_date
        }
      end
    }

    File.write(DATA_FILE, JSON.pretty_generate(data))
    say_info("Data saved to #{DATA_FILE}")
  rescue StandardError => e
    say_error("Failed to save data: #{e.message}")
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
    say_error("Failed to load data: invalid JSON in #{DATA_FILE} (#{e.message})")
  rescue StandardError => e
    say_error("Failed to load data: #{e.message}")
  end

  def start
    loop do
      begin
        case main_menu_choice
        when 1 then admin_menu
        when 2 then register_customer
        when 3
          customer_id, acc_id, password = customer_login
          customer_menu(customer_id, acc_id, password)
        when 4
          say_info("Exiting...")
          break
        else
          raise ArgumentError, "Invalid choice."
        end
      rescue StandardError => e
        say_error("Error: #{e.message}")
      end
    end
  rescue Interrupt
    say_warning("Exiting safely...")
  rescue EOFError => e
    say_error(e.message)
  end

  private

  def divider
    Rainbow("-" * 60).faint.to_s
  end

  def section(title)
    puts
    puts divider
    puts Rainbow(title).bright.blue
    puts divider
  end

  def say_info(message)
    puts Rainbow(message).cyan
  end

  def say_success(message)
    puts Rainbow(message).green
  end

  def say_warning(message)
    puts Rainbow(message).yellow
  end

  def say_error(message)
    puts Rainbow(message).red
  end

  def main_menu_choice
    section("Bank Management System")
    @prompt.select("Choose an option:") do |menu|
      menu.choice "Admin", 1
      menu.choice "Register Customer", 2
      menu.choice "Customer Login", 3
      menu.choice "Exit", 4
    end
  end

  def admin_menu_choice
    section("Admin Panel")
    @prompt.select("Choose an option:") do |menu|
      menu.choice "Add a new Bank", 1
      menu.choice "View Registered Customers", 2
      menu.choice "Create Account", 3
      menu.choice "View Pending Loan Approvals", 4
      menu.choice "Approve Loan", 5
      menu.choice "Disburse Interest", 6
      menu.choice "View Account Details", 7
      menu.choice "View Transactions", 8
      menu.choice "View Top 5 Transactions", 9
      menu.choice "View Customer with Highest Balance", 10
      menu.choice "View Customers with No Loans", 11
      menu.choice "Approve Loan Closure Requests", 12
      menu.choice "Customers with Loans Exceeding 5x Account Balance", 13
      menu.choice "Projected Income from Active Loans in Next 12 Months", 14
      menu.choice "Estimate Tenure Reduction from Prepayment", 15
      menu.choice "Back to Main Menu", 16
    end
  end

  def customer_menu_choice(customer, account)
    section("Customer Panel")
    say_info("Welcome #{customer.name}! Logged into account #{account.acc_id} (#{account.acc_type})")
    @prompt.select("Choose an option:") do |menu|
      menu.choice "View Account Details", 1
      menu.choice "Deposit", 2
      menu.choice "Withdraw", 3
      menu.choice "Transfer Amount", 4
      menu.choice "View Bank Statement", 5
      menu.choice "Get Loan", 6
      menu.choice "View Loan Details", 7
      menu.choice "Pay EMI", 8
      menu.choice "Request Loan Closure", 9
      menu.choice "Deactivate Account", 10
      menu.choice "Back to Main Menu", 11
    end
  end

  def build_customers(customer_data)
    return {} unless customer_data

    customer_data.each_with_object({}) do |(id, customer), customers|
      customers[id.to_i] = Customer.new(
        customer['customer_id'],
        customer['name'],
        customer['dob'],
        customer['phone'],
        build_address(customer['address']),
        customer['password'],
        customer['status'] || 'registered',
        customer['created_at']
      )
    end
  end

  def build_address(address_data)
    case address_data
    when Hash
      Address.new(
        address_data['street'] || address_data[:street],
        address_data['city'] || address_data[:city],
        address_data['state'] || address_data[:state],
        address_data['zip_code'] || address_data[:zip_code]
      )
    else
      Address.new(nil, nil, nil, nil)
    end
  end

  def format_address(address)
    address.to_s
  end

  def build_banks(bank_data)
    return {} unless bank_data

    bank_data.each_with_object({}) do |(id, bank), banks|
      banks[id.to_i] = BankService::Bank.new(
        bank['bank_id'],
        bank['bank_name'],
        bank['loan_rate'] || bank['rate']
      )
    end
  end

  def build_accounts(account_data)
    return {} unless account_data

    account_data.each_with_object({}) do |(id, account), accounts|
      accounts[id.to_i] =
        if account['acc_type'] == 'Savings'
          BankService::SavingsAccount.new(
            account['bank_id'],
            account['acc_id'],
            account['customer_id'],
            account['balance'],
            account['status'] || 'active',
            account['created_at']
          )
        else
          BankService::CurrentAccount.new(
            account['bank_id'],
            account['acc_id'],
            account['customer_id'],
            account['balance'],
            account['status'] || 'active',
            account['created_at']
          )
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
      loans[id.to_i] = BankService::Loans.new(
        loan['loan_id'],
        loan['customer_id'],
        loan['acc_id'],
        loan['principal'],
        loan['loan_rate'],
        loan['tenure'],
        loan['emi'],
        loan['status'],
        loan['loan_start_date'],
        loan['loan_end_date'],
        installments_paid: loan['installments_paid'] || 0,
        installments_remaining: loan['installments_remaining'],
        amount_paid: loan['amount_paid'] || 0.0,
        amount_remaining: loan['amount_remaining']
      )
    end
  end

  def admin_menu
    loop do
      begin
        case admin_menu_choice
        when 1 then add_bank
        when 2 then show_registered_customers
        when 3 then create_account
        when 4 then show_pending_approvals
        when 5 then approve_loan(prompt_with_attempts { prompt_integer("Enter loan ID to approve:") })
        when 6 then distribute_interest
        when 7 then show_account_details(prompt_with_attempts { prompt_integer("Enter account ID to view details:") })
        when 8 then show_transactions(prompt_with_attempts { prompt_integer("Enter account ID to view transactions:") })
        when 9 then show_top_transactions
        when 10 then show_customer_with_highest_balance
        when 11 then show_customers_with_no_loans
        when 12 then approve_loan_closure(prompt_with_attempts { prompt_integer("Enter loan ID to approve closure:") })
        when 13 then show_customers_with_loans_exceeding_5x_balance
        when 14 then puts show_projected_interest_next_12_months
        when 15 then show_prepayment_tenure_reduction
        when 16 then break
        else
          raise ArgumentError, "Invalid choice."
        end
      rescue StandardError => e
        say_error("Error: #{e.message}")
      end
    end
  end

  def customer_menu(customer_id, acc_id, password)
    customer, account = fetch_customer_account(customer_id, acc_id, password)
    if account.status == "deactivated"
      say_warning("This account is deactivated. Please contact the bank for more information.")
      return
    else
      loop do
        begin
          case customer_menu_choice(customer, account)
          when 1 then show_account_details(acc_id)
          when 2 then deposit(acc_id)
          when 3 then withdraw(acc_id)
          when 4 then transfer_amount(acc_id, prompt_with_attempts { prompt_integer("Enter receiver account ID:") })
          when 5 then show_transactions(acc_id)
          when 6 then get_loan(customer_id, acc_id)
          when 7 then show_loan_details(customer_id)
          when 8 then pay_emi(customer_id, acc_id, prompt_with_attempts { prompt_integer("Enter loan ID to pay EMI:") })
          when 9 then request_loan_closure(customer_id, acc_id, prompt_with_attempts { prompt_integer("Enter loan ID to request closure:") })
          when 10 then deactivate_account(acc_id)
          when 11 then break
          else
            raise ArgumentError, "Invalid choice."
          end
        rescue StandardError => e
          say_error("Error: #{e.message}")
        end

        account = fetch_account(acc_id)
      end
    end
  end

  def get_valid_input(prompt, regex, error_msg, attempts = 3)
    attempts.times do |i|
      input = @prompt.ask(Rainbow(prompt).cyan.to_s, required: true)
      return input if input.match?(regex)
      say_warning("#{error_msg} #{attempts - 1 - i} attempts left.")
    end
    nil
  end

  def prompt(message)
    value = @prompt.ask(Rainbow(message).cyan.to_s, required: true)
    raise ArgumentError, "Input cannot be empty." if value.empty?

    value.strip
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
      say_error("Error: #{e.message}")
      raise if remaining <= 0
      say_warning("Attempts left: #{remaining}")
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

  def distribute_interest
    @accounts.each_value do |account|
      next unless account.status == "active"
      interest =
        if account.acc_type == "Savings"
          BankService::SavingsAccount.calculate_interest(account.balance)
        else
          BankService::CurrentAccount.calculate_interest(account.balance)
        end

      account.deposit(interest)

      transaction_id = (@transactions.keys.max || 0) + 1
      @transactions[transaction_id] = BankService::Transactions.new(account.acc_id, "interest received", interest)
    end

    save_data
    say_success("Interest distributed successfully.")
  end

  def fetch_customer_account(customer_id, acc_id, password)
    customer = fetch_customer(customer_id)
    account = fetch_account(acc_id)
    raise RuntimeError, "This account does not belong to the given customer." unless account.customer_id == customer_id
    raise RuntimeError, "Invalid password." if customer.password != password

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

  def customer_age(customer)
    Customer.calculate_age(customer.dob)
  end

  def customer_login
    customer_id = prompt_with_attempts { prompt_integer("Enter your customer ID:") }
    acc_id = prompt_with_attempts { prompt_integer("Enter your account ID:") }
    password = prompt_with_attempts { prompt("Enter your password:") }
    customer, account = fetch_customer_account(customer_id, acc_id, password)
    raise RuntimeError, "Customer is inactive. Please contact the bank." if customer.status == "inactive"
    raise RuntimeError, "This account is deactivated. Please contact the bank." if account.status == "deactivated"

    say_success("Welcome #{customer.name}!")
    say_info("Logged into account #{acc_id} (#{account.acc_type})")

    [customer_id, acc_id, password]
  end

  def add_bank
    bank_name = prompt_with_attempts { prompt("Enter bank name:") }
    loan_rate = prompt_with_attempts { prompt_amount("Enter interest rate:") }
    bank_id = (@banks.keys.max || 0) + 1

    bank = BankService::Bank.new(bank_id, bank_name, loan_rate)
    @banks[bank_id] = bank

    save_data
    say_success("Bank added successfully with ID: #{bank_id}")
  end

  def register_customer
    name = get_valid_input("Enter customer name:", /^(?=.{2,30}$)[A-Za-z]+(?:\s[A-Za-z]+)*$/, "Invalid name.")
    return say_warning("Failed to register customer.") unless name

    dob = get_valid_input("Enter date of birth (YYYY-MM-DD):", /^\d{4}-\d{2}-\d{2}$/, "Invalid date format.")
    return say_warning("Failed to register customer.") unless dob

    age = Customer.calculate_age(dob)
    return say_warning("Please enter a valid date of birth.") if age.nil?
    return say_warning("Age must be between 18 and 120.") unless age.between?(18, 120)

    phone = get_valid_input("Enter customer phone (10 digits):", /^\d{10}$/, "Invalid phone number.")
    return say_warning("Failed to register customer.") unless phone

    password = prompt_with_attempts { prompt("Set your account password:") }
    return say_warning("Failed to register customer.") unless password

    address = Address.new(
      prompt_with_attempts { prompt("Enter your street:") },
      prompt_with_attempts { prompt("Enter your city:") },
      prompt_with_attempts { prompt("Enter your state:") },
      prompt_with_attempts { prompt("Enter your zip code:") }
    )

    customer_id = (@customers.keys.max || 0) + 1

    customer = Customer.new(customer_id, name, dob, phone, address, password, "registered")
    @customers[customer_id] = customer

    save_data
    say_success("Customer registered successfully! Customer ID: #{customer_id}")
  end

  def create_account
    if @banks.empty?
      return say_warning("No banks available. Please ask an admin to add a bank first.")
    end

    if @customers.empty?
      return say_warning("No registered customers found. Ask the customer to register first.")
    end

    customer_id = prompt_with_attempts { prompt_integer("Enter customer ID:") }
    customer = fetch_customer(customer_id)

    say_info("Creating account for #{customer.name} (Customer ID: #{customer.customer_id})")

    bank_id = @prompt.select("Select bank:") do |menu|
      @banks.each do |id, bank|
        menu.choice "#{bank.bank_name} (ID: #{id}, Rate: #{bank.loan_rate}%)", id
      end
    end

    acc_type = @prompt.select("Select account type:", ["Savings", "Current"])
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
    say_success("Account created successfully! Account ID: #{acc_id}, Customer ID: #{customer_id}")
  end

  def deposit(acc_id)
    acc = fetch_account(acc_id)
    amount = prompt_with_attempts { prompt_amount("Enter the amount to deposit:") }

    acc.deposit(amount)

    transaction_id = (@transactions.keys.max || 0) + 1
    @transactions[transaction_id] = BankService::Transactions.new(acc_id, "deposit", amount)

    save_data
    say_success("Transaction successful! Current balance: #{format('%.2f', acc.balance)}")
  end

  def withdraw(acc_id)
    acc = fetch_account(acc_id)
    amount = prompt_with_attempts { prompt_amount("Enter the amount to withdraw:") }

    if acc.withdraw(amount)
      transaction_id = (@transactions.keys.max || 0) + 1
      @transactions[transaction_id] = BankService::Transactions.new(acc_id, "withdrawal", amount)
      save_data
      say_success("Transaction successful! Current balance: #{format('%.2f', acc.balance)}")
    else
      say_warning("Insufficient balance.")
    end
  end

  def transfer_amount(sender_id, receiver_id)
    sender_acc = fetch_account(sender_id)
    receiver_acc = fetch_account(receiver_id)
    return say_warning("Cannot transfer to the same account.") if sender_id == receiver_id

    amount = prompt_with_attempts { prompt_amount("Enter the amount to transfer:") }

    if sender_acc.withdraw(amount)
      receiver_acc.deposit(amount)

      t_id1 = (@transactions.keys.max || 0) + 1
      @transactions[t_id1] = BankService::Transactions.new(sender_id, "account_transfer", amount)

      t_id2 = t_id1 + 1
      @transactions[t_id2] = BankService::Transactions.new(receiver_id, "account_transfer", amount)

      save_data
      say_success("Transfer successful!")
      say_info("Sender balance: #{format('%.2f', sender_acc.balance)}")
    else
      say_warning("Insufficient balance.")
    end
  end

  def get_loan(customer_id, acc_id)
    principal = prompt_with_attempts { prompt_amount("Enter the principal amount:") }

    account = fetch_account(acc_id)
    bank = @banks[account.bank_id]
    raise RuntimeError, "Bank not found for this account." if bank.nil?

    rate = bank.loan_rate

    tenure = prompt_with_attempts { prompt_integer("Enter tenure in months:") }
    return say_warning("Invalid tenure.") if tenure <= 0

    emi_value = BankService::Loans.calculate_emi(principal, rate, tenure)
    loan_id = (@loans.keys.max || 0) + 1

    loan = BankService::Loans.new(loan_id, customer_id, acc_id, principal, rate, tenure, emi_value, "pending")
    @loans[loan_id] = loan

    save_data
    say_success("Loan request submitted. Loan ID: #{loan_id}, Estimated EMI: #{format('%.2f', emi_value)}")
  end

  def approve_loan(loan_id)
    loan = fetch_loan(loan_id)

    if loan.status != "pending"
      return say_warning("Loan is not in pending status.")
    end

    account = fetch_account(loan.acc_id)
    account.deposit(loan.principal)

    transaction_id = (@transactions.keys.max || 0) + 1
    @transactions[transaction_id] = BankService::Transactions.new(loan.acc_id, "loan_disbursement", loan.principal)
    loan.status = "approved"
    save_data
    say_success("Loan #{loan_id} approved successfully!")
  end

  def show_loan_details(customer_id)
    fetch_customer(customer_id)
    customer_loans = @loans.values.select { |loan| loan.customer_id == customer_id }

    if customer_loans.empty?
      say_warning("No loans found for this customer.")
    else
      section("Loan Details")
      customer_loans.each do |loan|
        say_info("Loan ID: #{loan.loan_id}")
        puts "Principal: #{format('%.2f', loan.principal)} | Rate: #{loan.loan_rate}% | Tenure: #{loan.tenure}m | EMI: #{format('%.2f', loan.emi)}"
        puts "Amount Paid: #{loan.amount_paid.round(2)} | Amount Remaining: #{loan.amount_remaining.round(2)} | Status: #{loan.status}"
        puts "Loan Start Date: #{loan.loan_start_date} | Loan End Date: #{loan.loan_end_date}"
        puts "Installments Paid: #{loan.installments_paid} | Installments Remaining: #{loan.installments_remaining}"
        puts divider
      end
    end
  end

  def pay_emi(customer_id, acc_id, loan_id)
    loan = fetch_loan(loan_id)
    return say_warning("You can only pay EMI for your own loan.") unless loan.customer_id == customer_id && loan.acc_id == acc_id
    return say_warning("Only approved loans can be paid.") unless loan.status == "approved"

    acc = fetch_account(acc_id)
    if acc.withdraw(loan.emi)
      transaction_id = (@transactions.keys.max || 0) + 1
      @transactions[transaction_id] = BankService::Transactions.new(loan.acc_id, "emi_payment", loan.emi)
      loan.amount_paid += loan.emi
      total_payable = (loan.emi * loan.tenure).round(2)
      loan.amount_remaining = [total_payable - loan.amount_paid, 0.0].max.round(2)
      loan.installments_paid += 1
      loan.installments_remaining -= 1

      loan.status = "closed" if loan.amount_paid >= total_payable

      say_success("EMI payment successful! Remaining account balance: #{format('%.2f', acc.balance)}")
      say_info("Total loan paid: #{loan.amount_paid.round(2)} / #{total_payable}")

      if loan.status == "closed"
        loan.amount_remaining = 0.0
        loan.installments_remaining = 0
        say_success("Congratulations! Your loan is fully paid and now closed.")
      end

      save_data
    else
      say_warning("Insufficient account balance to pay EMI.")
    end
  end

  def request_loan_closure(customer_id, acc_id, loan_id)
    loan = fetch_loan(loan_id)
    return say_warning("You can only request closure for your own loan.") unless loan.customer_id == customer_id && loan.acc_id == acc_id
    if loan.status != "approved"
      return say_warning("Only approved loans can be closed.")
    end
    if loan.amount_remaining > 0
      puts say_warning("Cannot request closure. Pay the remaining amount of: #{loan.amount_remaining.round(2)}")
      puts say_info("You can pay the remaining amount by making additional EMI payments or a lump sum payment equal to the remaining amount.")
      puts say_info("To make a lump sum payment, Enter 1. To continue with regular EMI payments, Enter 2.")
      choice = @prompt.select("Choose an option:") do |menu|
        menu.choice "Lump Sum Payment", 1
        menu.choice "Continue EMI Payments", 2
      end
      if choice == 1
        acc = fetch_account(acc_id)
        if acc.withdraw(loan.amount_remaining)
          transaction_id = (@transactions.keys.max || 0) + 1
          @transactions[transaction_id] = BankService::Transactions.new(loan.acc_id, "loan_closure_payment", loan.amount_remaining)
          loan.amount_paid += loan.amount_remaining
          loan.amount_remaining = 0.0
          loan.installments_paid += loan.installments_remaining
          loan.installments_remaining = 0
          say_success("Lump sum payment successful! Your loan is now fully paid.")
        else
          say_warning("Insufficient account balance to make lump sum payment.")
          return
        end
      else
        pay_emi(customer_id, acc_id, loan_id)
        return
      end
    end
    loan.status = "closure_requested"
    save_data
    say_success("Loan closure requested for Loan ID: #{loan_id}")
  end

  def show_pending_approvals
    pending_loans = @loans.values.select { |loan| loan.status == "pending" }
    return say_warning("No pending loan approvals found.") if pending_loans.empty?
    section("Pending Loan Approvals")
    pending_loans.each do |loan|
      customer = fetch_customer(loan.customer_id)
      account = fetch_account(loan.acc_id)
      bank = @banks[account.bank_id]
      puts "Loan ID: #{loan.loan_id} | Customer: #{customer.name} (ID: #{customer.customer_id}) | Account ID: #{account.acc_id} | Bank: #{bank.bank_name} | Principal: #{format('%.2f', loan.principal)} | Rate: #{loan.loan_rate}% | Tenure: #{loan.tenure}m | EMI: #{format('%.2f', loan.emi)}"
    end
  end

  def approve_loan_closure(loan_id)
    loan = fetch_loan(loan_id)
    if loan.status != "closure_requested"
      return say_warning("No closure request found for this loan.")
    end
    loan.status = "closed"
    save_data
    say_success("Loan ID: #{loan_id} has been closed successfully!")
  end

  def deactivate_account(acc_id)
    acc = fetch_account(acc_id)
    customer = fetch_customer(acc.customer_id)
    active_loans = @loans.values.find { |loan| loan.acc_id == acc_id && loan.amount_remaining > 0 }
    if active_loans
      return say_warning("Cannot deactivate account with active loans. Please pay off remaining loan amount: #{active_loans.amount_remaining.round(2)}")
    end
    if acc.balance > 0
      withdraw_amount = acc.balance
      acc.withdraw(withdraw_amount)
      transaction_id = (@transactions.keys.max || 0) + 1
      @transactions[transaction_id] = BankService::Transactions.new(acc_id, "withdrawal", withdraw_amount)
      say_info("Withdrew remaining balance of #{format('%.2f', withdraw_amount)} before deactivation.")
    end
    acc.status = "deactivated"
    customer.status = "inactive"
    refresh_customer_status(customer.customer_id)
    save_data
    say_success("Account #{acc_id} has been deactivated.")
  end

  def show_account_details(acc_id)
    acc = fetch_account(acc_id)

    customer = @customers[acc.customer_id]
    age = customer_age(customer)

    section("Account Details")
    puts "Account ID: #{acc_id}"
    puts "Customer: #{customer.name}"
    puts "DOB: #{customer.dob}"
    puts "Age: #{age || 'Unknown'}"
    puts "Customer Registered At: #{customer.created_at}"
    puts "Customer Status: #{customer.status}"
    puts "Address: #{format_address(customer.address)}"
    puts "Account Type: #{acc.acc_type}"
    puts "Balance: #{format('%.2f', acc.balance)}"
    puts "Account Created At: #{acc.created_at}"
    puts divider
  end

  def show_transactions(acc_id)
    fetch_account(acc_id)

    section("Transactions for Account #{acc_id}")

    account_txns = @transactions.values.select { |txn| txn.acc_id == acc_id }

    if account_txns.empty?
      say_warning("No transactions found.")
    else
      account_txns.each do |txn|
        puts "[#{txn.timestamp}] #{Rainbow(txn.type.capitalize).bright.yellow}: #{format('%.2f', txn.amount)}"
      end
    end

    puts divider
  end

  def show_pending_closures
    requests = @loans.values.select { |loan| loan.status == "closure_requested" }
    return say_warning("No pending closure requests.") if requests.empty?

    requests.each do |loan|
      puts "Loan ID: #{loan.loan_id} | Customer ID: #{loan.customer_id}"
    end
  end

  def top_transactions
    @transactions.values.sort_by { |t| -t.amount }.first(5)
  end

  def show_top_transactions
    section("Top 5 Transactions")
    top_transactions.each do |t|
      puts "Account ID: #{t.acc_id} | Type: #{t.type} | Amount: #{format('%.2f', t.amount)} | Timestamp: #{t.timestamp}"
    end
  end

  def show_customer_with_highest_balance
    account = @accounts.values.max_by { |acc| acc.balance }
    return say_warning("No accounts available.") if account.nil?

    customer = @customers[account.customer_id]
    age = customer_age(customer)
    section("Customer with Highest Balance")
    say_success("Customer with highest balance: #{customer.name} (Customer ID: #{customer.customer_id})")
    puts "DOB: #{customer.dob} | Age: #{age || 'Unknown'}"
    puts "Account ID: #{account.acc_id} | Balance: #{format('%.2f', account.balance)}"
  end

  def show_registered_customers
    return say_warning("No registered customers found.") if @customers.empty?

    section("Registered Customers")
    @customers.values.sort_by(&:customer_id).each do |customer|
      account_count = @accounts.values.count { |account| account.customer_id == customer.customer_id }
      age = customer_age(customer)
      puts "Customer ID: #{customer.customer_id} | Name: #{customer.name} | DOB: #{customer.dob} | Age: #{age || 'Unknown'} | Status: #{customer.status} | Registered At: #{customer.created_at} | Phone: #{customer.phone} | Address: #{format_address(customer.address)} | Accounts: #{account_count}"
    end
  end

  def show_customers_with_no_loans
    loaned_customers = @loans.values.map(&:customer_id).uniq
    customers = @customers.values.reject { |customer| loaned_customers.include?(customer.customer_id) }

    return say_warning("All customers have at least one loan.") if customers.empty?

    section("Customers with No Loans")
    customers.each do |customer|
      age = customer_age(customer)
      puts "Customer ID: #{customer.customer_id} | Name: #{customer.name} | DOB: #{customer.dob} | Age: #{age || 'Unknown'} | Status: #{customer.status}"
    end
  end

  def show_customers_with_loans_exceeding_5x_balance
    risky_loans = @loans.values.select do |loan|
      customer_accounts = @accounts.values.select { |account| account.customer_id == loan.customer_id }
      total_balance = customer_accounts.sum(&:balance)

      loan.principal > 5 * total_balance
    end

    return say_warning("No customers found with loans exceeding 5x account balance.") if risky_loans.empty?

    section("Loans Exceeding 5x Account Balance")
    risky_loans.each do |loan|
      customer = fetch_customer(loan.customer_id)
      customer_accounts = @accounts.values.select { |account| account.customer_id == loan.customer_id }
      total_balance = customer_accounts.sum(&:balance)
      puts "Loan ID: #{loan.loan_id} | Customer: #{customer.name} (ID: #{customer.customer_id}) | Loan Principal: #{format('%.2f', loan.principal)} | Total Balance: #{format('%.2f', total_balance)}"
    end
  end

  def show_projected_interest_next_12_months
    active_loans = @loans.values.select do |loan|
      loan.status == 'approved' && loan.amount_remaining.to_f.positive?
    end

    active_loans.sum do |loan|
      monthly_rate = loan.loan_rate.to_f / (12 * 100.0)
      paid_installments = [(loan.amount_paid.to_f / loan.emi.to_f).round, loan.tenure].min
      remaining_installments = [loan.tenure - paid_installments, 0].max
      current_balance = loan.principal.to_f
      total_interest_for_loan = 0

      paid_installments.times do
        monthly_interest = current_balance * monthly_rate
        principal_payment = loan.emi - monthly_interest
        current_balance = [current_balance - principal_payment, 0.0].max
      end

      [12, remaining_installments].min.times do
        break if current_balance <= 0

        monthly_interest = current_balance * monthly_rate
        total_interest_for_loan += monthly_interest

        principal_payment = loan.emi - monthly_interest
        current_balance = [current_balance - principal_payment, 0.0].max
      end

      total_interest_for_loan.round(2)
    end
  end

  def show_prepayment_tenure_reduction
    loan_id = prompt_with_attempts { prompt_integer("Enter loan ID:") }
    loan = fetch_loan(loan_id)
    prepayment_amount = prompt_with_attempts { prompt_amount("Enter one-time principal payment amount:") }
    months_saved = loan.months_reduced_by_prepayment(prepayment_amount)

    section("Prepayment Tenure Reduction")
    puts "Loan ID: #{loan.loan_id}"
    puts "Prepayment Amount: #{format('%.2f', prepayment_amount)}"
    puts "Current Remaining Tenure: #{loan.installments_remaining} months"
    puts "Months Reduced: #{months_saved}"
    puts "Estimated New Remaining Tenure: #{[loan.installments_remaining - months_saved, 0].max} months"
  rescue StandardError => e
    say_error("Unable to calculate tenure reduction: #{e.message}")
  end

end

system = BankSystem.new
system.start
