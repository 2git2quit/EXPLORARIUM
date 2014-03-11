class Level < ActiveRecord::Base
  attr_accessible :level_code, :level_name
  belongs_to :payment
  belongs_to :attendance
  
  validates :level_code, :presence => true
  validates :level_name, :presence => true
  validates :level_code,  :uniqueness => true
  validates :level_name,  :uniqueness => true
end
