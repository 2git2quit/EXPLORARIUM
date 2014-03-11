class Leave < ActiveRecord::Base
  attr_accessible :staff_id, :schedule_date,  :status, :time
  validates :staff_id, :presence => true 
  validates :schedule_date, :presence => true 
  
  belongs_to :staff

  HUMANIZED_ATTRIBUTES = {
  	  :staff_id => "Staff"
  }

  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

 # validates_uniqueness_of :student_id, :program_id , :newfee

end
