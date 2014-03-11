class Student < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  attr_accessible :father, :father_contact_number, :firstname, :lastname, :mother, :mother_contact_number, :school , :registration_date , :status , :dob , :siblings, :email_address1, :email_address2
  validates :lastname, :presence => true 
  validates :firstname, :presence => true
  #validates :lastname,  :uniqueness => {:scope => :firstname}
  validate :name_uniqueness => {:on => :create}
  has_many :payments
  has_many :attendances
  serialize :siblings
  
  HUMANIZED_ATTRIBUTES = {
  	  :lastname => "Lastname",
  	  :firstname => "Firstname"
  }

  def self.human_attribute_name(attr)
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
  

  def name_uniqueness
    existing_record = Student.find(:first, :conditions => ["lastname = ? AND firstname = ?", lastname, firstname])
    unless existing_record.blank?
      errors.add(:Student, "already exist")
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
 
  def is_birthday_coming?
    unless dob.nil? 	  
      mmdd = dob.strftime('%m%d') 
      mmdd == Time.now.strftime('%m%d')
   else
	false  
   end
  end
  
  def must_bill?(pid=nil)
    retval = false 	  
    bill = Array.new
    msgcodes = Array.new
    msgs = Array.new

    sum_newfee = Payment.sum(:newfee,:conditions => ["(student_id = ?) ",id]) || 0

=begin 
   if pid.nil?
      sum_newfee = Payment.sum(:newfee,:conditions => ["(student_id = ?) ",id]) || 0
      payments = Payment.order(:payment_date).find(:all,:conditions => ["student_id = ?",id] )
    else
      sum_newfee = Payment.sum(:newfee,:conditions => ["(student_id = ?) and id = ?",id,pid]) || 0
      payments = Payment.order(:payment_date).find(:all,:conditions => ["student_id = ? and id = ?",id,pid] )
    end
=end
    if pid.nil?
       attended = Attendance.select('program_id, max(session_date) as `session_date`, sum(hours) as `hours` ').group("program_id").find(:all,:conditions => ["student_id = ?",id])
    else
       attended = Attendance.select('program_id, max(session_date) as `session_date`, sum(hours) as `hours` ').group("program_id").find(:all,:conditions => ["student_id = ? and program_id = ?",id,pid])
    end
    if attended.size > 0
         attended.each do |a|
            h = Hash.new
            msgcodes = Array.new
            msgs = Array.new
            program = Program.find(:first,:conditions => ["id = ?",a.program_id])
            pays = Payment.find(:all,:conditions => ["student_id = ? and valid_date > ? and program_id = ?",id,a.session_date,program.id])
            if  (pays.size == 0)
              h[:program_name] = program.name
              h[:program_cost] = program.cost
              h[:program_id] = program.id
              h[:payment_date] = nil
              msgcodes << -5
              msgs << "Overdue"
              h[:message_codes] = msgcodes
              h[:messages] = msgs
              h[:unpaid_date] = a.session_date
              h[:unpaid_hours] = a.hours
              h[:unpaid_cost] = program.cost + program.new_student_fee
              bill << h
              retval = retval || true
            else
              #################
              pays.each do |p|
                h = Hash.new    
                msgcodes = Array.new
                msgs = Array.new

                h[:payment_id] = p.id
                h[:payment_date] = p.payment_date
                h[:valid_date] = p.valid_date
                h[:program_id] = p.program_id
                h[:program_name] = p.program.name
                h[:program_cost] = p.program.cost
                h[:program_regfee] = p.program.new_student_fee

                if (p.program.cycle == 365)
                   h[:hours_expected] = p.hours.nil? ? 0 : p.hours
                else
                   h[:hours_expected] = p.program.number_of_sessions * p.program.hours_per_session
                end
                h[:hours_consumed] = a.hours

                unpaid_hours = 0
                unpaid_cost = 0
                h[:unpaid_date] = a.session_date
                if (h[:hours_expected] <  a.hours )
                  msgs << "Unpaid Hours :  #{a.hours - h[:hours_expected]} hours"
                  h[:extra_hours] = a.hours - h[:hours_expected]
                  unpaid_hours = unpaid_hours + h[:extra_hours]
                  unpaid_cost = unpaid_cost +  h[:program_cost]
                  msgcodes << -2
                  retval = retval || true
                end

                if ( (status.nil? || status==0) && (sum_newfee <  p.program.new_student_fee ))
                  msgs << "Unpaid Registration fee : #{number_with_precision(p.program.new_student_fee.to_f - sum_newfee.to_f, :precision => 2)}"
                  h[:receivable_newfee] = p.program.new_student_fee.to_f - sum_newfee.to_f
                  unpaid_cost = unpaid_cost +  h[:receivable_newfee]
                  msgcodes << -4
                  retval = retval || true
                end

                if (p.amount_paid < p.program.cost)
                  msgs << "Unpaid Enrollment fee : #{number_with_precision(p.program.cost - p.amount_paid, :precision => 2)}"
                  msgs << "#{p.override_reason}"
                  h[:receivable_tuitionfee] = p.program.cost - p.amount_paid  
                  unpaid_cost = unpaid_cost + h[:receivable_tuitionfee]
                  msgcodes << -3
                  retval = retval || true
                end

                if ( ( (p.valid_date < Time.now + 3.days) && (p.valid_date > Time.now) ) && (retval == false) )
                  msgs << "Advance payment notification"
                  unpaid_hours = (program.hours_per_session * program.number_of_sessions) 
                  unpaid_cost = program.cost
                  msgcodes << 3
                  retval = retval || true
                end

                h[:unpaid_hours] = unpaid_hours
                h[:unpaid_cost] = unpaid_cost


               end #pays.each do |p|

               h[:message_codes] = msgcodes
               h[:messages] = msgs
               bill << h
              #################
            end # if  (payment.nil?)
          end # attended.each do |a|
       
    end
 return retval,bill
=begin
    payments.each do |p|
      h = Hash.new	  
      msgcodes = Array.new
      msgs = Array.new
      attended = Attendance.sum(:hours,:conditions => ["student_id = ? and program_id = ? and (session_date >= ? and  session_date <= ?) ", p.student_id,p.program_id,p.start_date,p.valid_date])
      h[:payment_id] = p.id
      h[:payment_date] = p.payment_date
      h[:valid_date] = p.valid_date
      h[:program_id] = p.program_id
      h[:program_name] = p.program.name
      h[:program_cost] = p.program.cost
      h[:program_regfee] = p.program.new_student_fee
      if (p.program.cycle == 365)
      	 h[:hours_expected] = p.hours.nil? ? 0 : p.hours
      else
         h[:hours_expected] = p.program.number_of_sessions * p.program.hours_per_session
      end
      h[:hours_consumed] = attended
      
      if ((p.valid_date < Time.now) && (attended < h[:hours_expected]))
        msgs << "Payment has Expired"	  
        msgcodes << -1
        retval = retval || true
      end
      if ((p.valid_date < Time.now + 3.days) && (p.valid_date > Time.now) )
        msgs << "Advance payment notification"
        msgcodes << 3
        retval = retval || true
      end
      if (h[:hours_expected] <  attended )
 	      msgs << "Unpaid Hours :  #{attended.to_f - h[:hours_expected].to_f} hours"
      	h[:extra_hours] = attended.to_f - h[:hours_expected].to_f
        msgcodes << -2
        retval = retval || true
      end
      if ( (status.nil? || status==0) && (sum_newfee <  p.program.new_student_fee ))
         msgs << "Unpaid Registration fee : #{number_with_precision(p.program.new_student_fee.to_f - sum_newfee.to_f, :precision => 2)}"
         h[:receivable_newfee] = p.program.new_student_fee.to_f - sum_newfee.to_f
         msgcodes << -4
         retval = retval || true
      end
      if (p.amount_paid < p.program.cost)
      	msgs << "Unpaid Enrollment fee : #{number_with_precision(p.program.cost - p.amount_paid, :precision => 2)}"
      	msgs << "#{p.override_reason}"
        h[:receivable_tuitionfee] = p.program.cost - p.amount_paid	
        msgcodes << -3
        retval = retval || true
      end
      h[:message_codes] = msgcodes
      h[:messages] = msgs
      bill << h
    end
    return retval,bill
=end    
  end
  
  def to_be_billed?(options=nil)
    retval = false
    msgs = Array.new
    msgcodes = Array.new

    allpayments = Payment.find(:first,:conditions => ["student_id = ? and newfee > 0 ",id])
    payments = Payment.select('program_id, count(program_id) as pcount, sum(amount_paid) as amount_paid , sum(newfee) as new_fee').group(:program_id).find(:all,:conditions => ["(student_id = ?)",id])
    sum_amount_paid = Payment.sum(:amount_paid,:conditions => ["student_id = ?",id]) || 0
    sum_newfee = Payment.sum(:newfee,:conditions => ["(student_id = ?) ",id]) || 0
    max_valid_date =  Payment.maximum("valid_date",:conditions => ["student_id = ?",id])
    billing_details = Hash.new
    billing_details[:program_cost_sum] = 0
    billing_details[:program_enrollment_fee] = 0
    billing_details[:expected_hours] = 0
    payments.each do |payment|
      cycle = payment.program.cycle.nil? ? 1 : payment.program.cycle	    
      mc = MonthCovered.select('month, count(month) as pcount').group(:month).find(:all,:conditions => ["(student_id = ? and program_id = ?)",id,payment.program.id])
      billing_details[:program_cost_sum] = billing_details[:program_cost_sum] + (payment.program.cost  * (mc.length / cycle)  )
      billing_details[:program_enrollment_fee] = billing_details[:program_enrollment_fee] + payment.program.new_student_fee
      billing_details[:expected_hours] = billing_details[:expected_hours] + (payment.program.hours_per_session * payment.program.number_of_sessions)  * (mc.length / cycle) 
    end
    billing_details[:paid_amount_sum] = sum_amount_paid || 0
    billing_details[:paid_enrollment_fee_sum] = sum_newfee || 0
    
    # number of hours taken is more than paid sessions
    unless max_valid_date.nil?
      exceed_attendances = Attendance.select('program_id, count(program_id) as pcount, sum(hours) as hours').group(:program_id).find(:all,:conditions => ["session_date > ? and student_id = ?", max_valid_date,id] )
      unless (exceed_attendances.nil? || exceed_attendances.empty?)
        billing_details[:exceeded_hours] = 0
        exceed_attendances.each do |attendance|                                
           billing_details[:exceeded_hours] = billing_details[:exceeded_hours] + attendance.hours      
        end
        retval = retval || true	    
        msgs << "Payment has Expired"	  
        msgcodes << -1
      end  
      
    end   

    advance = Payment.order("valid_date desc").find(:first,:conditions => ["student_id = ? and datediff(valid_date,curdate()) > 0 and datediff(valid_date,curdate()) < 4  and valid_date is not null", id] )
    unless advance.nil? 
        retval = retval || true	  
        billing_details[:expiration] = advance.valid_date
        billing_details[:program] = advance.program.name
        billing_details[:cost] = advance.program.cost
        billing_details[:newfee] = advance.program.new_student_fee
        msgs << "Advance payment notification"
        msgcodes << 3
      end
      

      max_valid_date =  Payment.maximum("coalesce(valid_date, '2020-01-01')",:conditions => ["student_id = ?",id])
      attendances = Attendance.select('program_id, count(program_id) as pcount, sum(hours) as hours').group(:program_id).find(:all,:conditions => ["session_date <= ? and student_id = ?", max_valid_date,id] )
      billing_details[:attended_hours] = 0
      attendances.each do |attendance|
      	 billing_details[:attended_hours] = billing_details[:attended_hours] + attendance.hours      
      end
      #billing_details[:unpaid_hours] = billing_details[:unpaid_hours].to_f - billing_details[:expected_hours].to_f   
      unless options.nil?
      	  billing_details[:attended_hours] = (billing_details[:attended_hours] - options[:old_hours]) + options[:new_hours]
      end
      if (billing_details[:attended_hours] > billing_details[:expected_hours])
        retval = retval || true	  
        unpaid = billing_details[:attended_hours]  - billing_details[:expected_hours]
        msgs << "Unpaid Hours : #{unpaid} hours"
        msgcodes << -2
      end

    
    # check if enrollment fee is paid
    if ((self.status == 0) && (sum_newfee < billing_details[:program_enrollment_fee]))
      puts "<<<<<<< REG FEE :::: #{self.inspect}"
      retval = retval || true	    
      unpaid = billing_details[:program_enrollment_fee]-sum_newfee
      msgs << "Unpaid Registration fee : #{number_with_precision(unpaid, :precision => 2)}"
      msgcodes << -4
    end

    # check if program fee is paid
    if ((sum_amount_paid < billing_details[:program_cost_sum])  )
      retval = retval || true	
      unpaid = billing_details[:program_cost_sum] - sum_amount_paid 
      msgs << "Unpaid Enrollment fee : #{number_with_precision(unpaid, :precision => 2)}"	
      msgcodes << -3
    end

    return retval,msgs,billing_details,msgcodes
  end
 
  
  def getPrevStatus(now)
     
	  payments = Payment.order("valid_date desc").find(:all,:conditions => ["(student_id = ?) and valid_date <= ? ",id,now],:limit => 2)
     status = 0
     unless (payments.nil?)
     
     # NEW
     if (payments.nil? || payments.empty?)
     	 return 0
     end
     if (payments.size == 1)
        # NEW: first time payment and less than a month ago
       if ((payments[0].valid_date > now - 2.months) )
       	   return 0
        # INACTIVE: 
       else
       	   return 3    
       end
     else
       if (payments[1].valid_date  <  (payments[0].valid_date - 2.months) ) && (payments[0].valid_date < now)
     	    return 2 # RETURNING
       elsif  (payments[0].valid_date > (now - 1.months) )
     	    return 1 # OLD: more than once payment and less than a month ago
       end
     end
     
     
     end  # unless
     
     return status
  end

  def getStatus(now=Date.today)
   
     if !(status.nil?)
        return self.status
     end
     payments = Payment.order("valid_date desc").find(:all,:conditions => ["(student_id = ?)",id],:limit => 2)
     status = 0
     unless (payments.nil?)
     	     
     # NEW
     if (payments.nil? || payments.empty?)
     	 return 0
     end

     if (payments.size == 1)
        # NEW: first time payment and less than a month ago
        if ((payments[0].valid_date > 2.month.ago) && (payments[0].program.cycle != 3) )
       	   return 0
        end  
        if ( (payments[0].start_date < 1.month.ago) && (payments[0].program.cycle == 3))
          return 1
       end
        # INACTIVE:
        if ( (payments[0].valid_date < 2.month.ago) )
          return 3    
       end

     else
       if (payments[1].valid_date  <  (payments[0].valid_date - 2.months) ) 
     	    return 2 # RETURNING
       elsif  (payments[0].valid_date > (now - 1.months) )
     	    return 1 # OLD: more than once payment and less than a month ago
       end
     end
     
     
     end  # unless
     
     return status
  end
  
  private
  
  
end
