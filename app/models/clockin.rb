class Clockin < ActiveRecord::Base
	
  attr_accessible :staff_id, :time_in, :time_out
  
  belongs_to :staff
end
