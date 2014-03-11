class Staff < ActiveRecord::Base
	attr_accessible :attendance, :classes, :dob, :firstname, :lastname, :leaves, :status , :contact_no , :emergency_contact
  validates :lastname, :presence => true 
  validates :firstname, :presence => true
  validates :status, :presence => true
#  validate :name_uniqueness => {:on => :create}
  validates_uniqueness_of :lastname, :scope => :firstname

  belongs_to :leave

  HUMANIZED_ATTRIBUTES = {
    	    :lastname => "Name",
    	    :firstname => "Name"
  }

  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  
  def name_uniqueness
    existing_record = Staff.find(:first, :conditions => ["lastname = ? AND firstname = ?", lastname, firstname])
    unless existing_record.blank?
    	errors.add(:Staff, "already exist")
    end
  end
   
  def is_birthday?
    unless dob.nil? 	  
      mmdd = dob.strftime('%m%d') 
      mmdd == Time.now.strftime('%m%d')
   else
	false  
   end
  end


end
