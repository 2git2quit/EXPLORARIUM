require 'digest/sha1'
require 'socket'

class UsersController < ApplicationController
	before_filter :require_authentication , :except => [:login, :logout, :authenticate, :generate_report , :reports_and_alerts , :print_form]
   
	
  def billing
   s = Student.find(params[:id])
   payment = Payment.find(:first,:conditions => ["student_id = ? and program_id = ? ",s.id,params[:program_id].to_i ])
   program = payment.program
   params[:student] = s
   params[:payment] = payment
   params[:program] = program
  end

  def overdue
   s = Student.find(params[:id])
   stat,billing = s.must_bill?
   payment = Payment.find(:first,:conditions => ["student_id = ? and program_id = ? ",s.id,params[:program_id].to_i ])
   program = payment.program unless payment.nil?
   params[:student] = s
   params[:payment] = payment unless payment.nil?
   params[:program] = program unless payment.nil?
   params[:billing] = billing
  end
 
  def advance_billing
   s = Student.find(params[:id])
   stat,billing = s.must_bill?
   payment = Payment.find(:first,:conditions => ["student_id = ? and program_id = ? ",s.id,params[:program_id].to_i ])
   program = payment.program unless payment.nil?
   params[:student] = s
   params[:payment] = payment unless payment.nil?
   params[:program] = program unless payment.nil?
   params[:billing] = billing
  end

	# GET /users
  # GET /users.json
  def index
    if session[:role].eql? "MANAGEMENT" 	  
       @users = User.all
    else
    	@users = User.find(:all,:conditions => ["username = ?",session[:username]])
    end	    

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new
    @roles = ["MANAGEMENT","CENTER MANAGER", "STAFF",]
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
    @roles = ["MANAGEMENT","CENTER MANAGER", "STAFF"]

  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])
    encrypted_password= Digest::SHA1.hexdigest(params[:user][:password])
    if (params[:user][:role].blank?)
      @user.role = "STAFF"
    end
    @user.password = encrypted_password
    
    respond_to do |format|
      if @user.save
      	@users = User.find(:all)
        format.html {render :action => "index"}
      else
       	@validates = Array.new
        @user.errors.messages.each do |m|
          @validates << m    
        end
       @roles = ["MANAGEMENT","CENTER MANAGER", "STAFF"]
        format.html { render :action => "new" }
          format.json { render :json => @user.errors, :status => :unprocessable_entity }
        end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])
    encrypted_password= Digest::SHA1.hexdigest(params[:user][:password])
    params[:user][:password] = encrypted_password
    @user.password = encrypted_password
    respond_to do |format|
      if @user.update_attributes(params[:user])
      	@users = User.find(:all)
        format.html {render :action => "index"}
      else
      	@validates = Array.new
        @user.errors.messages.each do |m|
          @validates << m    
        end
        format.html { render :action => "edit" }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    respond_to do |format|
    	    format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end
  
  
  def login
    @user = User.new
    @path = session[:protected_page]
  end
  
  def logout
     @validation_error = "User has logged out"
     @user = User.new
     session[:username] = nil
     session[:operator] = nil
     session[:protected_page] = "/students"
     respond_to do |format|
       format.html { redirect_to("/login")}
       format.json { head :no_content }
     end     
  end
  
  def authenticate
     encrypted_password= Digest::SHA1.hexdigest(params[:user][:password])
     @user = User.find(:first, :conditions => ["username = ? and password = ?",params[:user][:username],encrypted_password])
     #@exp = User.find(:first, :conditions => ["username = ? and password = ? and datediff(curdate(),created_at) < 32",params[:user][:username],encrypted_password])
    @exp = false
     @trial = false
     if (@exp.nil?)
         @host = Socket.gethostname
    	 audit_log(session[:username],"Trial License has expired")
    	 @host = "Trial License has expired.  Serial #: 19AD0-0F1Y#{@host}95-DE19"
    	 @trial = true
    	 @user = nil
     end
    if (@user.nil?) 
     audit_log(session[:username],"Unsuccessful Login Attempt using user :#{params[:user][:username]}")
     if !@trial
        @validation_error = "Invalid Login Id or Password"
     else
        @validation_error = ""
     end
     respond_to do |format|
      #params[:user][:path] = session[:protected_page]
      format.html { render :action => "login" }
      format.json { head :no_content }
     end
    else
     session[:username] = params[:user][:username]
     session[:role] = User.find_by_username(params[:user][:username]).role
     session[:delimiter] = ","
     session[:expires_at] = 600.minutes.from_now
     session[:company] = "Explorarium Co. LTD"
     session[:hours] = 0.5

     audit_log(session[:username],"Logged in as :#{params[:user][:username]}")
     respond_to do |format|
     	format.html { redirect_to(params[:user][:path]) }
        format.json { head :no_content }
     end
    end    
  end
  
  def home
    @students = Student.order("lastname").find(:all)
    @programs = Program.order("name").find(:all)
    @levels = Level.find(:all)

    @reports = [[1, "Attendance Report"],[5, "New Enrollees Report"],[2, "Payment Notice Report"],[3, "Sales Report By Program"],[4, "Sales Report By Date"],[6, "Total Sales Report"],[7, "Exceeded number of Sessions"]]
    @months = ['JANUARY','FEBRUARY','MARCH', 'APRIL', 'MAY', 'JUNE','JULY', 'AUGUST','SEPTEMBER','OCTOBER','NOVEMBER','DECEMBER']
    @years = [2010,2011,2012,2013,2014,2015,2016,2017]
  end

  def attendance_report(params)
    conditions = ""
    title = "Attendance Report"
    unless params[:student_id].blank?
        conditions = "student_id = #{params[:student_id].to_i}"
        student = Student.find_by_id(params[:student_id].to_i)
        title = "#{title} of #{student.firstname}  #{student.lastname} "
    else    
        title = "#{title} of all students "
    end
    unless params[:level_id].blank?
        unless conditions.blank? 
           conditions = "#{conditions} and level_id = #{params[:level_id].to_i}"
        else
           conditions = "level_id = #{params[:level_id].to_i}"
        end   
        level = Level.find_by_id(params[:level_id].to_i)
        title = "#{title} on #{level.name}"
    end
    unless params[:program_id].blank?
        unless conditions.blank? 
           conditions = "#{conditions} and program_id = #{params[:program_id].to_i}"
        else
           conditions = "program_id = #{params[:program_id].to_i}"
        end  
        program = Program.find_by_id(params[:program_id].to_i)
        title = "#{title} taking #{program.name}"
    end

    unless params[:from_date].blank?
        unless conditions.blank? 
           conditions = "#{conditions} and session_date >= STR_TO_DATE('#{params[:from_date]}','%m/%d/%Y')"
        else
           conditions = "session_date >= STR_TO_DATE('#{params[:from_date]}','%m/%d/%Y')"
        end   
        title = "#{title} starting #{params[:from_date]}"
    end

    unless params[:to_date].blank?
        unless conditions.blank? 
           conditions = "#{conditions} and session_date <= STR_TO_DATE('#{params[:to_date]}','%m/%d/%Y')"
        else
           conditions = "session_date <= STR_TO_DATE('#{params[:to_date]}','%m/%d/%Y')"
        end   
        title = "#{title} to #{params[:to_date]}"
    end

    return conditions,title
  end

  def payment_notice_report(params)
    conditions = ""
    title = "Payment Notice Report"
    unless params[:student_id].blank?
        conditions = "student_id = #{params[:student_id].to_i}"
        student = Student.find_by_id(params[:student_id].to_i)
        title = "#{title} of #{student.firstname}  #{student.lastname} "
    else    
        title = "#{title} of all students "
    end
    unless params[:program_id].blank?
        unless conditions.blank? 
           conditions = "#{conditions} and program_id = #{params[:program_id].to_i}"
        else
           conditions = "program_id = #{params[:program_id].to_i}"
        end  
        program = Program.find_by_id(params[:program_id].to_i)
        title = "#{title} taking #{program.name}"
    end
     
    unless (params[:from_month].blank? || params[:from_year].blank?)
        unless conditions.blank? 
           conditions = "#{conditions} and (upper(monthname(session_date)) = '#{params[:from_month]}' and year(session_date) = #{params[:from_year]})"
        else
           conditions = "(upper(monthname(session_date)) = '#{params[:from_month]}' and year(session_date) = #{params[:from_year]})"
        end   
        title = "#{title} for the month of #{params[:from_month]} #{params[:from_year]} "
    end


    return conditions,title
  end


  def get_balance(student_id,conditions)
    
    if conditions.blank?
       attendances = Attendance.group("student_id").find(:all,:conditions => "student_id = #{student_id.to_i}")
    else   
        conditions = "#{conditions} and student_id = #{student_id.to_i}"
        attendances = Attendance.group("student_id").find(:all,:conditions => conditions)
    end
    total = 0
    programs = Array.new
    student = Student.find(student_id)
    attendances.each do |a|
       program = Program.find(:first,:conditions => "id = #{a.program_id.to_i}")
       unless program.nil?
           if (student.status != 0)    
             total = total + program.cost 
     	   else
     	     total = total + program.cost  +  program.new_student_fee
           end
           programs << program.name
       end    
    end

    paid = 0
    attendances.each do |a|
      payment = Payment.find(:first,:conditions => "student_id = #{student_id.to_i} and program_id = #{a.program_id.to_i} and amount_paid > 0")
      unless payment.nil?
        paid = paid + payment.amount_paid
      end
      payment = Payment.find(:first,:conditions => "student_id = #{student_id.to_i} and newfee > 0")
      unless payment.nil?
         paid = paid + payment.newfee
       end
    end

   return total,paid,programs

  end


  def income_report(params)
    conditions = ""
    title = "Income Report"
    if (params[:report_id].to_i == 4)
      title = "#{title} by Date"
    else
      title = "#{title} by Program"
    end
    unless params[:program_id].blank?
        unless conditions.blank? 
           conditions = "#{conditions} and program_id = #{params[:program_id].to_i}"
        else
           conditions = "program_id = #{params[:program_id].to_i}"
        end  
        program = Program.find_by_id(params[:program_id].to_i)
        title = "#{title} [#{program.name}]"
    end

    unless params[:from_date].blank?
        unless conditions.blank? 
           conditions = "#{conditions} and payment_date >= STR_TO_DATE('#{params[:from_date]}','%m/%d/%Y')"
        else
           conditions = "payment_date >= STR_TO_DATE('#{params[:from_date]}','%m/%d/%Y')"
        end   
        title = "#{title} starting #{params[:from_date]}"
    end

    unless params[:to_date].blank?
        unless conditions.blank? 
           conditions = "#{conditions} and payment_date <= STR_TO_DATE('#{params[:to_date]}','%m/%d/%Y')"
        else
           conditions = "payment_date <= STR_TO_DATE('#{params[:to_date]}','%m/%d/%Y')"
        end   
        title = "#{title} to #{params[:to_date]}"
    end

    return conditions,title
  end

  def new_enrollees_report(params)
    conditions = ""
    title = "New Enrollees Report"
    

    unless params[:from_date].blank?
        unless conditions.blank? 
           conditions = "#{conditions} and registration_date >= STR_TO_DATE('#{params[:from_date]}','%m/%d/%Y')"
        else
           conditions = "registration_date >= STR_TO_DATE('#{params[:from_date]}','%m/%d/%Y')"
        end   
        title = "#{title} starting #{params[:from_date]}"
    end

    unless params[:to_date].blank?
        unless conditions.blank? 
           conditions = "#{conditions} and registration_date <= STR_TO_DATE('#{params[:to_date]}','%m/%d/%Y')"
        else
           conditions = "registration_date <= STR_TO_DATE('#{params[:to_date]}','%m/%d/%Y')"
        end   
        title = "#{title} to #{params[:to_date]}"
    end
    
    if (params[:from_date].blank? && params[:to_date].blank?)
      conditions = "registration_date is not null"
      title = "#{title}"    
    end


    return conditions,title
  end

  def generate_report
    
    if (params[:report_id].to_i == 1)
      conditions,title = attendance_report(params)
      @attendances = Attendance.order("session_date").find(:all,:conditions => "#{conditions}")
      render :update do |page|
        page.replace_html("report_box" ,  :partial => "/users/report_attendance" , :locals => {:attendances => @attendances,:title => title}  )            
      end
    end


    if (params[:report_id].to_i == 2)
      conditions,title = payment_notice_report(params)
      notices = Array.new
      
      notice = Hash.new
      unless params[:student_id].blank?
          notice[:lastname] = Student.find_by_id(params[:student_id].to_i).lastname 
          notice[:firstname] = Student.find_by_id(params[:student_id].to_i).firstname
          notice[:total],notice[:paid],notice[:program] = get_balance(params[:student_id],conditions)
          notices[0] = notice
      else
        students = Student.find(:all)
        students.each do |student|
          notice = Hash.new
          notice[:lastname] = student.lastname 
          notice[:firstname] = student.firstname
          notice[:total],notice[:paid],notice[:program] = get_balance(student.id,conditions)
          notices << notice
        end
      end

      render :update do |page|
        page.replace_html("report_box" ,  :partial => "/users/report_payment" , :locals => {:notices => notices,:title => title}  )            
      end
    end


    if (params[:report_id].to_i == 3)
      conditions,title = income_report(params)
      notices = Array.new
      @payments = Payment.select('program_id, count(*) as cnt, sum(amount_paid) as `amount_paid` , sum(newfee) as `newfee`').group("program_id").find(:all,:conditions => "#{conditions}")
      render :update do |page|
        page.replace_html("report_box" ,  :partial => "/users/report_income" , :locals => {:payments => @payments,:title => title, :report_id => 3}  )            
      end
    end
    if (params[:report_id].to_i == 4)
      conditions,title = income_report(params)
      notices = Array.new
      @payments = Payment.select('payment_date, count(*) as cnt, sum(amount_paid) as `amount_paid` , sum(newfee) as `newfee`').group("payment_date").find(:all,:conditions => "#{conditions}")
      render :update do |page|
        page.replace_html("report_box" ,  :partial => "/users/report_income" , :locals => {:payments => @payments,:title => title, :report_id => 4}  )            
      end
    end

    if (params[:report_id].to_i == 5)
      conditions,title = new_enrollees_report(params)
      @students = Student.find(:all,:conditions => conditions)
      render :update do |page|
        page.replace_html("report_box" ,  :partial => "/users/report_new_student" , :locals => {:students => @students,:title => title}  )            
      end
    end
      
  if (params[:report_id].to_i == 6)
      conditions,title = income_report(params)
      p = Payment.order(:payment_date).find(:all,:conditions => conditions)      
      render :update do |page|
        page.replace_html("report_box" ,  :partial => "/users/report_sales" , :locals => {:sales => p,:title => "Sales Report"}  )            
      end
  end  

  if (params[:report_id].to_i == 7)
      conditions,title = attendance_report(params)
      @attendances = Attendance.select('student_id, program_id, level_id, max(session_date) as `session_date`, sum(hours) as `total_hours`').find(:all,:conditions => "#{conditions}", :group => 'student_id, program_id,level_id')
      render :update do |page|
      	      page.replace_html("report_box" ,  :partial => "/users/report_attendance_mismatch" , :locals => {:attendances => @attendances,:title => "Exceeded number of Sessions"}  )            
      end
  end  
 end
  
  
  def reports_and_alerts
    #prep instance var for reports 
    #@students_to_be_billed = Array.new
    @students = Student.order(:lastname).find(:all)
  end    
  def advance_payments
    @students = Student.order(:lastname).find(:all)
  end    

  def reports
    @students = Student.order(:lastname,:firstname).find(:all)
    @programs = Program.order("name").find(:all)
    @payments = Payment.order(:payment_date).find(:all)
    @levels = Level.find(:all)
    @years = [2010,2011,2012,2013,2014,2015,2016,2017]
    @frequency = ['DAILY','MONTHLY','QUARTERLY']
    @months = ['JANUARY','FEBRUARY','MARCH', 'APRIL', 'MAY', 'JUNE','JULY', 'AUGUST','SEPTEMBER','OCTOBER','NOVEMBER','DECEMBER']
    if (session[:role].eql? "MANAGEMENT")
      @reports = [[1, "Sales Report"],[2,"Student Birthdays"],[3,"Account Receivables"],[4,"Student Enrollment Status"],[5,"Student with Siblings"]]
    else
       @reports = [[1, "Sales Report"],[2,"Student Birthdays"] ,[4,"Student Enrollment Status"]]
    end
  end
  
  def filter_report
    where = "(1=1)"	
    @filters = Hash.new
    if (params[:report_id].nil? || params[:report_id].blank?) 
      params[:report_id] = 1
    end
    if (params[:report_frequency].nil? || params[:report_frequency].blank?)
      params[:report_frequency] = "DAILY"
    end
    
    if (params[:report_id].to_i == 1) # Sales Report
       title = "Sales Report"	    
       if !params[:program_id].nil? && !params[:program_id].blank?
    	  where = "#{where} and program_id = #{params[:program_id].to_i}"
    	  title = "#{title} for #{Program.find(params[:program_id].to_i).name}"    
       end 	  	  
       if !params[:level_id].nil? && !params[:level_id].blank?
    	 where = "#{where} and level_id = #{params[:level_id].to_i}"
    	 title = "#{title} for #{Level.find(params[:level_id].to_i).level_name}"    
       end 	  	  
       if !params[:student_id].nil? && !params[:student_id].blank?
       	  where = "#{where} and student_id = #{params[:student_id].to_i}"
       	  title = "#{title} for #{Student.find(params[:student_id].to_i).lastname}, #{Student.find(params[:student_id].to_i).firstname}"    
       end 	  	  
       if !params[:report_year].nil? && !params[:report_year].blank?
         where = "#{where} and year(payment_date) = #{params[:report_year].to_i}"
       end 	

       if params[:report_frequency].eql? "MONTHLY"
       	 @objects = Payment.select('year(payment_date) as yy, month(payment_date) as mm, sum(amount_paid) as amount_paid ,sum(newfee) as newfee, sum(charges) as charges ').group('year(payment_date),month(payment_date)').find(:all , :conditions => "#{where}")
         partial_file = "/users/report_monthly_sales"
         title = "Monthly #{title}"
       elsif params[:report_frequency].eql? "DAILY"
         @objects = Payment.order(:payment_date).find(:all,:conditions => "#{where}")
         partial_file = "/users/report_daily_sales"
         title = "Daily #{title}"
       elsif params[:report_frequency].eql? "QUARTERLY"
       	 @objects = Payment.select('year(payment_date) as yy,quarter(payment_date) as qq, month(payment_date) as mm, sum(amount_paid) as amount_paid ,sum(newfee) as newfee').group('year(payment_date),quarter(payment_date),month(payment_date)').find(:all , :conditions => "#{where}")
       	 partial_file = "/users/report_quarterly_sales"
         title = "Quarterly #{title}"
       end
    end # Sales Report
    

    if (params[:report_id].to_i == 2) # Student Birthday
        title = "Student Birthday Alert"
        where = "#{where} and dob is not null"
       if params[:report_frequency].eql? "MONTHLY"
       	 @objects = Student.select('month(dob) as mm, dob , lastname , firstname').group('month(dob),dob,lastname,firstname').find(:all , :conditions => "#{where}")
         partial_file = "/users/report_monthly_child_bday"
         title = "Monthly #{title}"
       elsif params[:report_frequency].eql? "DAILY"
       	 @objects = Student.select('month(dob) as mm, day(dob) as dd, dob , lastname , firstname').group('month(dob),day(dob), dob,lastname,firstname').find(:all , :conditions => "#{where}")
         partial_file = "/users/report_daily_child_bday"
         title = "Daily #{title}"
       end
    end # Student Birthday Report

     if (params[:report_id].to_i == 3) # AR Report
       title = "Account Receivables Report"	   
       #where_hash = Hash.new 
       if !params[:program_id].nil? && !params[:program_id].blank?
    	  #where = "#{where} and program_id = #{params[:program_id].to_i}"
    	  title = "#{title} for #{Program.find(params[:program_id].to_i).name}"    
        #where_hash.merge( {:attendances => {:program_id => params[:program_id]}  } )
        @filters[:program_id] = params[:program_id]
       end 	  	  
       if !params[:level_id].nil? && !params[:level_id].blank?
    	 #where = "#{where} and level_id = #{params[:level_id].to_i}"
    	 title = "#{title} for #{Level.find(params[:level_id].to_i).level_name}"    
        #where_hash.merge( {:attendances => {:level_id => params[:level_id]}  } )
        @filters[:level_id] = params[:level_id]
       end 	
       if !params[:student_id].nil? && !params[:student_id].blank?
       	  #where = "#{where} and student_id = #{params[:student_id].to_i}"
          where = "#{where} and id = #{params[:student_id].to_i}"
       	  title = "#{title} for #{Student.find(params[:student_id].to_i).lastname}, #{Student.find(params[:student_id].to_i).firstname}"    
       end 	  	  
       if !params[:report_year].nil? && !params[:report_year].blank?
         #where = "#{where} and year(payment_date) = #{params[:report_year].to_i}"
         @filters[:report_year] = params[:report_year]
       end 	

       if params[:report_frequency].eql? "MONTHLY"
       	 #@objects = Payment.order(:payment_date).find(:all , :conditions => "#{where}")
         partial_file = "/users/report_monthly_ar"
         title = "Monthly #{title}"
       elsif params[:report_frequency].eql? "DAILY"
         @objects = Student.order(:lastname , :firstname).find(:all, :conditions => "#{where}")
         #@objects = Student.joins(:attendances).where(where_hash).order(:lastname , :firstname).find(:all, :conditions => "#{where}")
         partial_file = "/users/report_daily_ar"
         title = "Daily #{title}"
       elsif params[:report_frequency].eql? "QUARTERLY"
       	 #@objects = Payment.order(:payment_date).find(:all , :conditions => "#{where}")
         @objects = Student.order(:lastname , :firstname).find(:all)
         partial_file = "/users/report_quarterly_ar"
         title = "Quarterly #{title}"
       end
    end # AR Report
   

    if (params[:report_id].to_i == 4) # Returning Students
    	setStatus
   	title = "Student Enrollment Status"
       where = "(1=1)"
       if !params[:program_id].nil? && !params[:program_id].blank?
    	  where = "#{where} and program_id = #{params[:program_id].to_i}"
    	  title = "#{title} for #{Program.find(params[:program_id].to_i).name}"    
       end 	  	  
       if !params[:level_id].nil? && !params[:level_id].blank?
    	 where = "#{where} and level_id = #{params[:level_id].to_i}"
    	 title = "#{title} for #{Level.find(params[:level_id].to_i).level_name}"    
       end 	  	  
       if !params[:student_id].nil? && !params[:student_id].blank?
       	  where = "#{where} and student_id = #{params[:student_id].to_i}"
       	  title = "#{title} for #{Student.find(params[:student_id].to_i).lastname}, #{Student.find(params[:student_id].to_i).firstname}"    
       end 	  	  
       if !params[:report_year].nil? && !params[:report_year].blank?
         where = "#{where} and year(payment_date) = #{params[:report_year].to_i}"
       end 	
        
       if params[:report_frequency].eql? "MONTHLY"
       	       @objects = Payment.select('payment_date,valid_date,student_id,program_id').group('payment_date,valid_date,student_id,program_id').find(:all , :conditions => "#{where}")
       	 partial_file = "/users/report_monthly_returning"
         title = "Monthly #{title}"
       elsif params[:report_frequency].eql? "DAILY"
       	       @objects = Payment.select('payment_date,valid_date,student_id,program_id').group('payment_date,valid_date,student_id,program_id').find(:all , :conditions => "#{where}")
         partial_file = "/users/report_daily_returning"
         title = "Daily #{title}"
       end
    end # Returning Students

    if (params[:report_id].to_i == 5) # Students with Siblings
        title = "Students with Siblings Report"	    
        @objects = Student.order(:lastname,:firstname).find(:all , :conditions => "siblings is not null")
        partial_file = "/users/report_siblings"
    end  # Students with Siblings
   

    
    @months = ['JANUARY','FEBRUARY','MARCH', 'APRIL', 'MAY', 'JUNE','JULY', 'AUGUST','SEPTEMBER','OCTOBER','NOVEMBER','DECEMBER']
    render :update do |page|
      page.replace_html("dtable" ,  :partial => partial_file , :locals => {:objects => @objects , :title => title , :filters => @filters}  )            
    end
  end
 

  private

  def setStatus
    @status = Array.new
    @status << {:id=>0,:name=>'New'}
    @status << {:id=>1,:name=>'Old'}
    @status << {:id=>2,:name=>'Returning'}
    @status << {:id=>3,:name=>'Inactive'}
  end

end
