class AuditLog < ActiveRecord::Base
	attr_accessible :log_date,:details, :username
end