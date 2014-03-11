class Schedule < ActiveRecord::Base
  attr_accessible :timeslot_id, :schedule_date, :program_id, :staff_id, :student_id
	
  belongs_to :student
  belongs_to :program
  belongs_to :staff

end
