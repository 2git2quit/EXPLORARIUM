class User < ActiveRecord::Base
  attr_accessible :fullname, :password, :username ,:role
  validates :username, :presence => true
  validates :password, :presence => true
  validates :username,  :uniqueness => true
  #validate :must_be_at_least_8_characters
    
  #def must_be_at_least_8_characters
  #  if password.length < 8
  #warnings.add(:password, "must be at least 8 characters") 
  #  end    	    
  #end 
end
