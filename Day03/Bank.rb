module BankService
  class Bank
    attr_accessor :bank_id, :bank_name, :rate

    def initialize(bank_id, bank_name, rate)
      @bank_id = bank_id
      @bank_name = bank_name
      @rate = rate
    end
  end

  class Account
    attr_accessor :bank_id, :acc_id, :customer_id, :balance, :status

    def initialize(bank_id,acc_id,customer_id,balance,status="active")
      @bank_id = bank_id
      @acc_id = acc_id
      @customer_id = customer_id
      @balance = balance
      @status = status
    end

    def deposit(amount)
      @balance += amount
    end

    def withdraw(amount)
      if @balance >= amount
        @balance -= amount
        true
      else
        false
      end
    end

  end

  class SavingsAccount < Account
    def acc_type
      "Savings"
    end

    def calculate_interest
      @balance * 0.08
    end
  end

  class CurrentAccount < Account
    def acc_type
      "Current"
    end

    def calculate_interest
      @balance * 0.05
    end

  end

  class Transactions
    attr_accessor :acc_id, :type, :amount, :timestamp

    def initialize(acc_id, type, amount)
      @acc_id = acc_id
      @type = type
      @amount = amount
      @timestamp = Time.now.strftime("%F %T")
    end
  end

  class Loans
    attr_accessor :loan_id, :customer_id, :acc_id, :principal, :rate, :tenure, :emi, :amount_paid, :amount_remaining, :status

    def initialize(loan_id, customer_id, acc_id, principal, rate, tenure, emi, status)
      @loan_id = loan_id
      @customer_id = customer_id
      @acc_id = acc_id
      @principal = principal
      @rate = rate
      @tenure = tenure
      @emi = emi
      @amount_paid = 0.0
      @amount_remaining = (emi * tenure).round(2)
      @status = status
    end

    def self.calculate_emi(principal, rate, tenure)
      monthly_rate = rate / (12 * 100.0)
      emi_value = principal * monthly_rate * (1 + monthly_rate)**tenure / ((1 + monthly_rate)**tenure - 1)
      emi_value
    end
  end
end
