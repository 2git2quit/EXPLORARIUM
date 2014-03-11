class Program < ActiveRecord::Base
	
  attr_accessible :cost, :hours_per_session, :name, :new_student_fee, :number_of_sessions , :cycle
  
  belongs_to :payment
  belongs_to :attendance
  
  validates :name, :presence => true
  validates :cost, :presence => true
  validates :hours_per_session, :presence => true
  validates :number_of_sessions, :presence => true
  validates :name,  :uniqueness => true
end
