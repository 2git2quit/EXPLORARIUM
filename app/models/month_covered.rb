class MonthCovered < ActiveRecord::Base
  attr_accessible :month, :year, :payment_id, :student_id , :program_id
  belongs_to :payments
end

