class Attendance < ActiveRecord::Base
  attr_accessible :level_id, :program_id, :session_date, :student_id , :hours
  validates :session_date, :presence => true 
  validates :student_id, :presence => true 
  validates :hours, :presence => true 
  validates :program_id, :presence => true 
  validate :attendance_uniqueness  => {:on => :create}
  
  belongs_to :student
  belongs_to :program
  belongs_to :level

  def attendance_uniqueness
    existing_record = Attendance.find(:first, :conditions => ["student_id = ? AND session_date = ?", student_id, session_date])
    unless existing_record.blank?
       errors.add(:Attendance, "already exist")
    end
  end
end
