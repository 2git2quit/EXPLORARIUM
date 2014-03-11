class SchedulesController < ApplicationController
  before_filter :require_authentication 
  # GET /schedules
  # GET /schedules.json
  def index
    @current_week = true
    generate_timeslot
    @staffs = Staff.order(:lastname,:firstname).find(:all)
    @levels = Level.order(:level_name).find(:all)
    @programs = Program.order(:name).find(:all)
    d = Date.today
    @monday = d.at_beginning_of_week + 7.days
    @onleave = Leave.find(:all,:conditions => ["schedule_date >= ? and schedule_date <= ?",@monday,@monday+7.days])
    @mondays = Schedule.group(:timeslot_id).find(:all,:conditions => ["schedule_date = ? ",@monday])
    if @mondays.nil? || @mondays.blank?
      generate_schedule_table
    end
    generate_daysofweek(@monday)
    @schedule = Schedule.find(:first)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @schedules }
    end
  end

  # GET /schedules/11
  # GET /schedules/1.json
  def show
    create
  end

  # GET /schedules/new                   
  # GET /schedules/new.json
  def new
    @schedule = Schedule.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @schedule }
    end
  end

  # GET /schedules/1/edit
  def edit
    create
  end

  # POST /schedules
  # POST /schedules.json
  def create
  	  
   @schedule = Schedule.find(:first)
   generate_timeslot
    @staffs = Staff.order(:lastname,:firstname).find(:all)
    #@students = Student.order(:lastname,:firstname).find(:all)
    @levels = Level.order(:level_name).find(:all)
    @programs = Program.order(:name).find(:all)
   if (params[:commit].eql? "<<")  
    d = Date.today
    @monday = d.at_beginning_of_week
    @onleave = Leave.find(:all,:conditions => ["schedule_date >= ? and schedule_date <= ?",@monday,@monday+7.days])
    @mondays = Schedule.group(:timeslot_id).find(:all,:conditions => ["schedule_date = ? ",@monday])
    if @mondays.nil? || @mondays.blank?
      generate_schedule_table
    end
    generate_daysofweek(@monday)
    @current_week = false
  elsif (params[:commit].eql? "Go to week")
    @monday = Date.parse(params[:session_date])
    @mondays = Schedule.group(:timeslot_id).find(:all,:conditions => ["schedule_date = ? ",@monday])
    if @mondays.nil? || @mondays.blank?
      generate_schedule_table
    end
    generate_daysofweek(@monday)
    @current_week = false
  else
  	  
    schedules = params[:schedule]
    unless schedules.nil?
      schedules.each do |time,day|
    	    day.each do |id,tab|
    	    	    tab.each do |i,table|
    	    	       scheds = Schedule.find(:all,:conditions => ["DATE_FORMAT(schedule_date,'%Y-%m-%d') = ? and timeslot_id = ? and table_no = ?" , table[:schedule_date],time,i])
    	    	       scheds.each do |schedule|
      	                 # add delete row in attendance when student is removed
     	    	         #if has_changed?(schedule,table)
     	    	         if true
    	    	           clear_attendance(schedule.student_1_id,table[:student_1_id].to_i,table[:schedule_date],time)
     	    	           clear_attendance(schedule.student_2_id,table[:student_2_id].to_i,table[:schedule_date],time)
     	    	           clear_attendance(schedule.student_3_id,table[:student_3_id].to_i,table[:schedule_date],time)
     	    	           clear_attendance(schedule.student_4_id,table[:student_4_id].to_i,table[:schedule_date],time)
     	    	           clear_attendance(schedule.student_5_id,table[:student_5_id].to_i,table[:schedule_date],time)
     	    	           clear_attendance(schedule.student_6_id,table[:student_6_id].to_i,table[:schedule_date],time)

   	       	           schedule.staff_id = table[:staff_id].to_i
   	       	           schedule.memo1 = table[:memo1]
   	       	           schedule.memo2 = table[:memo2]
   	       	           schedule.memo3 = table[:memo3]
   	       	           schedule.memo4 = table[:memo4]
   	       	           #schedule.level_id = table[:level_id].to_i
   	       	           #schedule.program_id = table[:program_id].to_i
      	                   schedule.student_1_id = table[:student_1_id].to_i
      	                   schedule.student_2_id = table[:student_2_id].to_i
      	                   schedule.student_3_id = table[:student_3_id].to_i
      	                   schedule.student_4_id = table[:student_4_id].to_i
      	                   schedule.student_5_id = table[:student_5_id].to_i
      	                   schedule.student_6_id = table[:student_6_id].to_i
      	                   
      	                   schedule.attended_1 =  ((table[:attended_1].nil? || table[:attended_1].blank?)) ? 'N' : table[:attended_1]
      	                   schedule.attended_2 =  ((table[:attended_2].nil? || table[:attended_2].blank?)) ? 'N' : table[:attended_2]
      	                   schedule.attended_3 =  ((table[:attended_3].nil? || table[:attended_3].blank?)) ? 'N' : table[:attended_3]
      	                   schedule.attended_4 =  ((table[:attended_4].nil? || table[:attended_4].blank?)) ? 'N' : table[:attended_4]
      	                   schedule.attended_5 =  ((table[:attended_5].nil? || table[:attended_5].blank?)) ? 'N' : table[:attended_5]
      	                   schedule.attended_6 =  ((table[:attended_6].nil? || table[:attended_6].blank?)) ? 'N' : table[:attended_6]
   	                   schedule.save
   	                 
                           generate_attendance(table,time)
                         end
    	    	       end
    	            end
    	    end
      end
    end
    d = Date.today
    if ("#{params[:current_week]}" == "false" && ("#{params[:commit]}"  == "Save") )
       @monday = d.at_beginning_of_week
       @current_week = false
    else
       @monday = d.at_beginning_of_week + 7.days
       @current_week = true
    end
    @mondays = Schedule.group(:timeslot_id).find(:all,:conditions => ["schedule_date = ? ",@monday])
    generate_daysofweek(@monday)
  end
  respond_to do |format|
     format.html {render :action => "index"}
  end
  end
  
  
  def print
    @schedules = Schedule.find(:all,:conditions => ["DATE_FORMAT(schedule_date,'%m/%d/%Y') = ?" , params[:schedule_date]])
    @schedule_by_slot = Schedule.select("timeslot_id, count(timeslot_id) as `count`").group(:timeslot_id).find(:all,:conditions => ["DATE_FORMAT(schedule_date,'%m/%d/%Y') = ? and (student_1_id <> 0 ||student_2_id <> 0 || student_3_id <> 0 || student_4_id <> 0 || student_5_id <> 0 || student_6_id <> 0)" , params[:schedule_date]])
    @slot = Array.new
    @schedule_by_slot.each do |slot|
    	    h = Hash.new
    	    h[:id] = slot.timeslot_id
    	    h[:count] = slot.count
    	    @slot[slot.timeslot_id] = h	
    end
    generate_timeslot
    render :update do |page|
            page.replace_html("daily_tracker_form" , :partial => "/schedules/daily_tracker" , :locals => {:schedules => @schedules , :timeslot =>  @timeslot }  ) 
    end

  end

  # PUT /schedules/1
  # PUT /schedules/1.json
  def update
    create
  end

  def destroy
    @schedule = Schedule.find(params[:id])
    @schedule.destroy
    audit_log(session[:username],"Deleted schedule ID:#{params[:id]}")
    respond_to do |format|
      format.html { redirect_to schedules_url }
      format.json { head :no_content }
    end
  end
  
  
  def add_student
    unless (params[:student_id].to_i == 0) 	  
      @schedule = Schedule.find(:first,:conditions => ["schedule_id = ? and student_id = ? " , params[:schedule_id].to_i,  params[:student_id].to_i])
      if (@schedule.nil?  || @schedule.blank?)
    	 @schedule = Schedule.new   
      end
      @schedule.student_id = params[:student_id].to_i
      @schedule.schedule_id = params[:schedule_id].to_i
      @schedule.save
      #unless (params[:staff_id].to_i == 0) 	  
      #  @schedule = Schedule.find(:all,:conditions => ["schedule_id = ?" , params[:schedule_id].to_i])
      #  @schedule.staff_id = params[:staff_id].to_i
      #  @schedule.save
      #end
    end
    @schedules = Schedule.order(:schedule_id).all
    @students = Student.all
    @staffs = Staff.all
    getsum
    render :index

  end

  def del_student
    @schedule = Schedule.find(:first,:conditions => ["schedule_id = ? and student_id = ? " , params[:schedule_id].to_i,  params[:student_id].to_i])
    unless @schedule.nil?
      @schedule.destroy
    end  
    @schedules = Schedule.order(:schedule_id).all
    @students = Student.all
    @staffs = Staff.all
    getsum
    render :index
  end

  def list_students
    @schedules = Schedule.find(:all,:conditions => ["schedule_id = ?" , params[:schedule_id].to_i])
    render :update do |page|
        page.replace_html("list_students" , :partial => "/schedules/list" , :locals => {:schedules => @schedules}  )      	    
    end

  end
  
  def generate_timeslot_1hr
    tables = 4
    @timeslot = Array.new
    hh = 9
    id = 0
    am_pm = 'AM'
    4.times do |i|
      if (hh+1 == 12)
        @timeslot << {:id => id , :name => "#{hh}:00 #{am_pm} - #{hh+1}:00 PM"}
         am_pm = 'PM'
      else
        @timeslot << {:id => id , :name => "#{hh}:00 #{am_pm} - #{hh+1}:00 #{am_pm}"}
      end
      id=id+1
      hh = hh + 1
    end
    hh = 1
    am_pm = 'PM'
    6.times do |i|
      @timeslot << {:id => id , :name => "#{hh}:00 #{am_pm} - #{hh+1}:00 #{am_pm}"}
      id=id+1
      hh=hh+1
    end
  end
  
   def generate_timeslot_30mins
    tables = 4
    @timeslot = Array.new
    hh = 9
    id = 0
    am_pm = 'AM'
    
    4.times do |i|
      @timeslot << {:id => id , :name => "#{hh}:00 #{am_pm} - #{hh}:30 #{am_pm}"}
      id=id+1
      if (hh+1 == 12)
        @timeslot << {:id => id , :name => "#{hh}:30 #{am_pm} - #{hh+1}:00 PM"}
         am_pm = 'PM'
      else
        @timeslot << {:id => id , :name => "#{hh}:30 #{am_pm} - #{hh+1}:00 #{am_pm}"}
      end
      id=id+1
      hh = hh + 1
    end
    hh = 1
    am_pm = 'PM'
    6.times do |i|
      @timeslot << {:id => id , :name => "#{hh}:00 #{am_pm} - #{hh}:30 #{am_pm}"}
      id=id+1
      @timeslot << {:id => id , :name => "#{hh}:30 #{am_pm} - #{hh+1}:00 #{am_pm}"}
      id=id+1
      hh=hh+1
    end
  end


  def generate_timeslot
   #generate_timeslot_1hr
   generate_timeslot_30mins
   slots = 10 # slots = 20 
  end

  def generate_daysofweek(monday)
      @daysofweek = Array.new
      @am_teachers = Array.new
      @pm_teachers = Array.new
      
       @staffs_mon_am = Staff.order(:lastname,:firstname).find(:all,:conditions => ["id not in (select staff_id from leaves where schedule_date = ? and time like '%AM%')" ,monday])
       @staffs_mon_pm = Staff.order(:lastname,:firstname).find(:all,:conditions => ["id not in (select staff_id from leaves where schedule_date = ? and time like '%PM%')" ,monday])
       @staffs_tue_am = Staff.order(:lastname,:firstname).find(:all,:conditions => ["id not in (select staff_id from leaves where schedule_date = ? and time like '%AM%')" ,monday+1.days])
       @staffs_tue_pm = Staff.order(:lastname,:firstname).find(:all,:conditions => ["id not in (select staff_id from leaves where schedule_date = ? and time like '%PM%')" ,monday+1.days])
       @staffs_wed_am = Staff.order(:lastname,:firstname).find(:all,:conditions => ["id not in (select staff_id from leaves where schedule_date = ? and time like '%AM%')" ,monday+2.days])
       @staffs_wed_pm = Staff.order(:lastname,:firstname).find(:all,:conditions => ["id not in (select staff_id from leaves where schedule_date = ? and time like '%PM%')" ,monday+2.days])
       @staffs_thu_am = Staff.order(:lastname,:firstname).find(:all,:conditions => ["id not in (select staff_id from leaves where schedule_date = ? and time like '%AM%')" ,monday+3.days])
       @staffs_thu_pm = Staff.order(:lastname,:firstname).find(:all,:conditions => ["id not in (select staff_id from leaves where schedule_date = ? and time like '%PM%')" ,monday+3.days])
       @staffs_fri_am = Staff.order(:lastname,:firstname).find(:all,:conditions => ["id not in (select staff_id from leaves where schedule_date = ? and time like '%AM%')" ,monday+4.days])
       @staffs_fri_pm = Staff.order(:lastname,:firstname).find(:all,:conditions => ["id not in (select staff_id from leaves where schedule_date = ? and time like '%PM%')" ,monday+4.days])
       @staffs_sat_am = Staff.order(:lastname,:firstname).find(:all,:conditions => ["id not in (select staff_id from leaves where schedule_date = ? and time like '%AM%')" ,monday+5.days])
       @staffs_sat_pm = Staff.order(:lastname,:firstname).find(:all,:conditions => ["id not in (select staff_id from leaves where schedule_date = ? and time like '%PM%')" ,monday+5.days])
       
       @am_teachers << @staffs_mon_am 
       @am_teachers << @staffs_tue_am 
       @am_teachers << @staffs_wed_am 
       @am_teachers << @staffs_thu_am 
       @am_teachers << @staffs_fri_am 
       @am_teachers << @staffs_sat_am 
       @pm_teachers << @staffs_mon_pm 
       @pm_teachers << @staffs_tue_pm 
       @pm_teachers << @staffs_wed_pm 
       @pm_teachers << @staffs_thu_pm 
       @pm_teachers << @staffs_fri_pm 
       @pm_teachers << @staffs_sat_pm 
       
       @teachers = Array.new
    6.times do |i|
        @daysofweek << @monday+i.days
        h = Hash.new
        h[:am] = @am_teachers[i]
        h[:pm] = @pm_teachers[i]
        @teachers << h
     end
  end
  
  def generate_schedule_table
    slots_count = 10
    tables = 4
    6.times do |i|
    	    slots_count.times do |j|
    	    	    tables.times do |k|   
    	    	      @schedules = Schedule.new
    	    	      @schedules.schedule_date = @monday + (i.days)
    	    	      @schedules.timeslot_id = @timeslot[j][:id] 
    	    	      @schedules.table_no = k 
    	    	      @schedules.attended_1 = 'Y'
    	    	      @schedules.attended_2 = 'Y'
    	    	      @schedules.attended_3 = 'Y'
    	    	      @schedules.attended_4 = 'Y'
    	    	      @schedules.attended_5 = 'Y'
    	    	      @schedules.attended_6 = 'Y'
    	    	      @schedules.save
                     end
            end
    end
  	  
  end

  
  def generate_attendance(table,i)
  	                 attendance1 = Attendance.find(:first,:conditions => ["student_id = ? and DATE_FORMAT(session_date,'%Y-%m-%d') = ? and timeslot_id = ?",table[:student_1_id].to_i,table[:schedule_date],i])
   	                 attendance2 = Attendance.find(:first,:conditions => ["student_id = ? and DATE_FORMAT(session_date,'%Y-%m-%d') = ? and timeslot_id = ? ",table[:student_2_id].to_i,table[:schedule_date],i])
   	                 attendance3 = Attendance.find(:first,:conditions => ["student_id = ? and DATE_FORMAT(session_date,'%Y-%m-%d') = ? and timeslot_id = ?",table[:student_3_id].to_i,table[:schedule_date],i])
   	                 attendance4 = Attendance.find(:first,:conditions => ["student_id = ? and DATE_FORMAT(session_date,'%Y-%m-%d') = ? and timeslot_id = ?",table[:student_4_id].to_i,table[:schedule_date],i])
   	                 attendance5 = Attendance.find(:first,:conditions => ["student_id = ? and DATE_FORMAT(session_date,'%Y-%m-%d') = ? and timeslot_id = ?",table[:student_5_id].to_i,table[:schedule_date],i])
   	                 attendance6 = Attendance.find(:first,:conditions => ["student_id = ? and DATE_FORMAT(session_date,'%Y-%m-%d') = ? and timeslot_id = ?",table[:student_6_id].to_i,table[:schedule_date],i])
                         if (attendance1.nil? || attendance1.blank?) 
                           attendance1 = Attendance.new 	 
                	   payment = Payment.order("payment_date desc").find(:first,:conditions => ["student_id = ? and DATE_FORMAT(start_date,'%Y-%m-%d') <= ? and DATE_FORMAT(valid_date,'%Y-%m-%d') >= ?",table[:student_1_id].to_i, table[:schedule_date],table[:schedule_date]])
                	   if (payment.nil? || payment.blank?)
                             attendance1.level_id = 1
                             attendance1.program_id = 1
                	   else 	    
                             attendance1.level_id = payment.level_id
                             attendance1.program_id = payment.program_id
                           end
                         end
                         if attendance2.nil? || attendance2.blank?
                            attendance2 = Attendance.new 	 
                	   payment = Payment.order("payment_date desc").find(:first,:conditions => ["student_id = ? and DATE_FORMAT(start_date,'%Y-%m-%d') <= ? and DATE_FORMAT(valid_date,'%Y-%m-%d') >= ?",table[:student_2_id].to_i, table[:schedule_date],table[:schedule_date]])
                	    if (payment.nil? || payment.blank?)
                              attendance2.level_id = 1
                              attendance2.program_id = 1
                	    else 	    
                              attendance2.level_id = payment.level_id
                              attendance2.program_id = payment.program_id
                            end
                         end
                         if attendance3.nil? || attendance3.blank?
                            attendance3 = Attendance.new 	 
                	   payment = Payment.order("payment_date desc").find(:first,:conditions => ["student_id = ? and DATE_FORMAT(start_date,'%Y-%m-%d') <= ? and DATE_FORMAT(valid_date,'%Y-%m-%d') >= ?",table[:student_3_id].to_i, table[:schedule_date],table[:schedule_date]])
                	    if (payment.nil? || payment.blank?)
                              attendance3.level_id = 1
                              attendance3.program_id = 1
                	    else 	    
                              attendance3.level_id = payment.level_id
                              attendance3.program_id = payment.program_id
                            end
                        end
                         if attendance4.nil? || attendance4.blank?
                            attendance4 = Attendance.new 	 
                	   payment = Payment.order("payment_date desc").find(:first,:conditions => ["student_id = ? and DATE_FORMAT(start_date,'%Y-%m-%d') <= ? and DATE_FORMAT(valid_date,'%Y-%m-%d') >= ?",table[:student_4_id].to_i, table[:schedule_date],table[:schedule_date]])
                	    if (payment.nil? || payment.blank?)
                              attendance4.level_id = 1
                              attendance4.program_id = 1
                	    else 	    
                              attendance4.level_id = payment.level_id
                              attendance4.program_id = payment.program_id
                            end
                         end
                         if attendance5.nil? || attendance5.blank?
                            attendance5 = Attendance.new 	 
                	   payment = Payment.order("payment_date desc").find(:first,:conditions => ["student_id = ? and DATE_FORMAT(start_date,'%Y-%m-%d') <= ? and DATE_FORMAT(valid_date,'%Y-%m-%d') >= ?",table[:student_5_id].to_i, table[:schedule_date],table[:schedule_date]])
                	    if (payment.nil? || payment.blank?)
                              attendance5.level_id = 1
                              attendance5.program_id = 1
                	    else 	    
                              attendance5.level_id = payment.level_id
                              attendance5.program_id = payment.program_id
                            end
                         end
                         if attendance6.nil? || attendance6.blank?
                            attendance6 = Attendance.new 	 
                	   payment = Payment.order("payment_date desc").find(:first,:conditions => ["student_id = ? and DATE_FORMAT(start_date,'%Y-%m-%d') <= ? and DATE_FORMAT(valid_date,'%Y-%m-%d') >= ?",table[:student_6_id].to_i, table[:schedule_date],table[:schedule_date]])
                	    if (payment.nil? || payment.blank?)
                              attendance6.level_id = 1
                              attendance6.program_id = 1
                	    else 	    
                              attendance6.level_id = payment.level_id
                              attendance6.program_id = payment.program_id
                            end
                         end

                         
                         attendance1.hours = (table[:attended_1] == "Y") ? session[:hours] : 0 
                         attendance1.student_id = table[:student_1_id].to_i
                         attendance1.session_date = table[:schedule_date]
                         attendance1.timeslot_id = i
                         unless table[:student_1_id].to_i == 0
                           attendance1.save
                         end

                         attendance2.hours = (table[:attended_2] == "Y") ? session[:hours] : 0 
                         attendance2.student_id = table[:student_2_id].to_i
                         attendance2.session_date = table[:schedule_date]
                         attendance2.timeslot_id = i
                         unless table[:student_2_id].to_i == 0
                           attendance2.save
                         end

                         attendance3.hours = (table[:attended_3] == "Y") ? session[:hours] : 0 
                         attendance3.student_id = table[:student_3_id].to_i
                         attendance3.session_date = table[:schedule_date]
                         attendance3.timeslot_id = i
                         unless table[:student_3_id].to_i == 0
                           attendance3.save
                         end

                         attendance4.hours = (table[:attended_4] == "Y") ? session[:hours] : 0 
                         attendance4.student_id = table[:student_4_id].to_i
                         attendance4.session_date = table[:schedule_date]
                         attendance4.timeslot_id = i
                         unless table[:student_4_id].to_i == 0
                           attendance4.save
                         end

                         attendance5.hours = (table[:attended_5] == "Y") ? session[:hours] : 0 
                         attendance5.student_id = table[:student_5_id].to_i
                         attendance5.session_date = table[:schedule_date]
                         attendance5.timeslot_id = i
                         unless table[:student_5_id].to_i == 0
                           attendance5.save
                         end

                         attendance6.hours = (table[:attended_6] == "Y") ? session[:hours] : 0 
                         attendance6.student_id = table[:student_6_id].to_i
                         attendance6.session_date = table[:schedule_date]
                         attendance6.timeslot_id = i
                         unless table[:student_6_id].to_i == 0
                           attendance6.save
                         end
                         
  end
  
  
  private
  
  def clear_attendance(old_id,new_id,date,time)
  	  if  (old_id != new_id)
  	     attendance = Attendance.find(:first,:conditions => ["student_id = ? and DATE_FORMAT(session_date,'%Y-%m-%d') = ? and timeslot_id = ? ",old_id,date,time])
      	     unless (attendance.nil? && attendance.blank?)
      	       attendance.destroy    
     	     end
      	  end
  end

  def has_changed?(schedule,table)
     retval = false
  	  
     if (schedule.staff_id == table[:staff_id].to_i)
        retval = retval || true
     end
     if (schedule.student_1_id == table[:student_1_id].to_i)
         retval = retval || true
     end	     	     
     if (schedule.student_2_id == table[:student_2_id].to_i)
         retval = retval || true
     end	     	     
     if (schedule.student_3_id == table[:student_3_id].to_i)
         retval = retval || true
     end	     	     
     if (schedule.student_4_id == table[:student_4_id].to_i)
         retval = retval || true
     end	     	     
     if (schedule.student_5_id == table[:student_5_id].to_i)
         retval = retval || true
     end	     	     
     if (schedule.student_6_id == table[:student_6_id].to_i)
         retval = retval || true
     end
     if (schedule.memo1 == table[:memo1])
         retval = retval || true
     end
     if (schedule.memo2 == table[:memo2])
         retval = retval || true
     end

     if (schedule.attended_1 == table[:attended_1])
         retval = retval || true
     end	     	     
     if (schedule.attended_2 == table[:attended_2])
         retval = retval || true
     end	     	     
     if (schedule.attended_3 == table[:attended_3])
         retval = retval || true
     end	     	     
     if (schedule.attended_4 == table[:attended_4])
         retval = retval || true
     end	     	     
     if (schedule.attended_5 == table[:attended_5])
         retval = retval || true
     end	     	     
     if (schedule.attended_6 == table[:attended_6])
         retval = retval || true
     end	     	     

     return retval     	     
   end


end
