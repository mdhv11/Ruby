module BankService
  class Bank
    attr_accessor :bank_id, :bank_name, :loan_rate

    def initialize(bank_id, bank_name, loan_rate)
      @bank_id = bank_id
      @bank_name = bank_name
      @loan_rate = loan_rate
    end
  end

  class Account
    attr_accessor :bank_id, :acc_id, :customer_id, :balance, :status, :created_at

    def initialize(bank_id,acc_id,customer_id,balance,status="active",created_at=nil)
      @bank_id = bank_id
      @acc_id = acc_id
      @customer_id = customer_id
      @balance = balance
      @status = status
      @created_at = created_at || Time.now.strftime("%F %T")
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

    def interest_rate
      8.0
    end

    def self.calculate_interest(balance)
      balance * 0.08
    end
  end

  class CurrentAccount < Account
    def acc_type
      "Current"
    end

    def interest_rate
      5.0
    end

    def self.calculate_interest(balance)
      balance * 0.05
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
    attr_accessor :loan_id, :customer_id, :acc_id, :principal, :loan_rate, :tenure, :installments_paid, :installments_remaining, :emi, :amount_paid, :amount_remaining, :status, :loan_start_date, :loan_end_date

    def initialize(loan_id, customer_id, acc_id, principal, loan_rate, tenure, emi, status, loan_start_date = nil, loan_end_date = nil, installments_paid: 0, installments_remaining: nil, amount_paid: 0.0, amount_remaining: nil)
      @loan_id = loan_id
      @customer_id = customer_id
      @acc_id = acc_id
      @principal = principal
      @loan_rate = loan_rate
      @tenure = tenure
      @installments_paid = installments_paid
      @installments_remaining = installments_remaining || (tenure - @installments_paid)
      @emi = emi
      @amount_paid = amount_paid
      @amount_remaining = amount_remaining || (emi * tenure).round(2)
      @status = status
      @loan_start_date = loan_start_date || Time.now.strftime("%F %T")
      @loan_end_date = loan_end_date || (Time.now + tenure * 30 * 24 * 60 * 60).strftime("%F %T")
    end

    def self.calculate_emi(principal, loan_rate, tenure)
      monthly_rate = loan_rate / (12 * 100.0)
      emi_value = principal * monthly_rate * (1 + monthly_rate)**tenure / ((1 + monthly_rate)**tenure - 1)
      emi_value
    end

    def outstanding_principal
      balance = principal.to_f
      monthly_rate = loan_rate.to_f / (12 * 100.0)

      return balance if monthly_rate.zero?

      installments_paid.to_i.times do
        monthly_interest = balance * monthly_rate
        principal_component = emi.to_f - monthly_interest
        balance = [balance - principal_component, 0.0].max
      end

      balance
    end

    def months_reduced_by_prepayment(prepayment_amount)
      amount = prepayment_amount.to_f
      raise ArgumentError, "Prepayment amount must be greater than zero." unless amount.positive?

      current_balance = outstanding_principal
      raise ArgumentError, "Loan is already fully paid." if current_balance <= 0

      monthly_rate = loan_rate.to_f / (12 * 100.0)
      current_remaining_months = installments_remaining.to_i
      reduced_balance = [current_balance - amount, 0.0].max

      new_remaining_months =
        if reduced_balance.zero?
          0
        elsif monthly_rate.zero?
          (reduced_balance / emi.to_f).ceil
        else
          numerator = Math.log(emi.to_f / (emi.to_f - reduced_balance * monthly_rate))
          denominator = Math.log(1 + monthly_rate)
          numerator.fdiv(denominator).ceil
        end

      [current_remaining_months - new_remaining_months, 0].max
    end
  end
end
