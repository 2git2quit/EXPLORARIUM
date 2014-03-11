class PaymentDetail < ActiveRecord::Base
	attr_accessible :payment_id,:cash_amount, :cheque_amount, :credit_card_amount, :cheque_bank_name, :cheque_number, :cheque_date, :credit_card_name, :credit_card_expirydate
end