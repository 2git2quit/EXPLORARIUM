class Payment < ActiveRecord::Base
	attr_accessible :amount_paid, :level_id,  :payment_details, :pr_no, :program_id, :student_id, :status, :newfee , :payment_date , :start_date, :valid_date , :card_no , :vat , :reservation_fee , :charges
  validates :student_id, :presence => true 
  validates :level_id, :presence => true 
  validates :program_id, :presence => true 
  validates :amount_paid, :presence => true 
  validates :payment_date, :presence => true 
  #validates :pr_no, :presence => true , :uniqueness => {:scope => :student_id , :on => :create}
  
  
  belongs_to :student
  belongs_to :program
  belongs_to :level
  has_many :month_covered
  belongs_to :payment
  belongs_to :attendance
  serialize :siblings
  
  HUMANIZED_ATTRIBUTES = {
  	  :amount_paid => "Amount Paid",
  	  :pr_no=> "PR #"
  }

  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

 # validates_uniqueness_of :student_id, :program_id , :newfee
 def self.attendances_covered
   attendances = Attendance.find(:all , :conditions => ["student_id = ? and program_id = ? and level_id = ?", student_id,program_id,level_id])	 
 end

end
