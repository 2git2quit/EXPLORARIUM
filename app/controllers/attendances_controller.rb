class AttendancesController < ApplicationController
before_filter :require_authentication

  # GET /attendances
  # GET /attendances.json
  def index
    @attendances = Attendance.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @attendances }
    end
  end

  # GET /attendances/1
  # GET /attendances/1.json
  def show
    @attendance = Attendance.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @attendance }
    end
  end

  # GET /attendances/new
  # GET /attendances/new.json
  def new
    @attendance = Attendance.new
    @students = Student.order("lastname").find(:all)
    @programs = Program.order("name").find(:all)
    @levels = Level.find(:all)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @attendance }
    end
  end

  # GET /attendances/1/edit
  def edit
    @attendance = Attendance.find(params[:id])
    @students = Student.order("lastname").find(:all)
    @programs = Program.order("name").find(:all)
    @levels = Level.find(:all)
    @history = Attendance.find(:all, :conditions => "student_id  = #{@attendance.student_id} and program_id = #{@attendance.program_id} " )
    @total_hours = 0
    @program = Program.find("#{@attendance.program_id}")  	    
    @history.each do |h|
       @total_hours = @total_hours + h.hours
    end
  end

  # POST /attendances
  # POST /attendances.json
  def create
      unless params[:attendance][:student_id].blank?
        lastpayment = Payment.find(:first,:conditions => ["student_id = ? and program_id = ?",params[:attendance][:student_id].to_i,params[:attendance][:program_id]])
      end
      unless lastpayment.nil?
         params[:attendance][:level_id] = lastpayment.level_id
      end   
      @attendance = Attendance.new(params[:attendance])
      save_stat = @attendance.save 
      respond_to do |format|
      	if (save_stat)
      	  @attendances = Attendance.find(:all)
          format.html {render :action => "index"}
        else
          @validates = Array.new
          @attendance.errors.messages.each do |m|
       	    @validates << m    
          end
         @students = Student.order("lastname").find(:all)
         @programs = Program.order("name").find(:all)
         @levels = Level.find(:all)
          format.html { render :action => "new" }
          format.json { render :json => @attendance.errors, :status => :unprocessable_entity }
        end
      end
  end

  # PUT /attendances/1
  # PUT /attendances/1.json
  def update
      @attendance = Attendance.find(params[:id])
      respond_to do |format|
        if @attendance.update_attributes(params[:attendance])
          @attendances = Attendance.find(:all)
          format.html {render :action => "index"}
        else
         @validates = Array.new
         @attendance.errors.messages.each do |m|
       	    @validates << m    
          end
          @students = Student.order("lastname").find(:all)
          @programs = Program.order("name").find(:all)
          @levels = Level.find(:all)
          @history = Attendance.find(:all, :conditions => "student_id  = #{@attendance.student_id} and program_id = #{@attendance.program_id} " )
          @total_hours = 0
          @program = Program.find("#{@attendance.program_id}")  	    
          @history.each do |h|
             @total_hours = @total_hours + h.hours
          end
          format.html { render :action => "edit" }
          format.json { render :json => @attendance.errors, :status => :unprocessable_entity }
        end
      end
  end

  # DELETE /attendances/1
  # DELETE /attendances/1.json
  def destroy
    @attendance = Attendance.find(params[:id])
    @attendance.destroy

    respond_to do |format|
      format.html { redirect_to attendances_url }
      format.json { head :no_content }
    end
  end
  
    def history
     if params[:id].blank?
      if (!params[:student_id].blank? && !params[:program_id].blank?)  	    
       @history = Attendance.find(:all, :conditions => "student_id  = #{params[:student_id]} and program_id = #{params[:program_id]}" )
       @program = Program.find("#{params[:program_id]}")  	    
      end
     else
       @history = Attendance.find(:all, :conditions => "id<> #{params[:id]} and student_id  = #{params[:student_id]} and program_id = #{params[:program_id]}" )
       @program = Program.find("#{params[:program_id]}")  	    
   end
     render :update do |page|
     	     page.replace_html("attendance_history" , :partial => "/attendances/history" , :locals => {:history => @history , :program => @program , :hours => params[:hours] , :session_date => params[:session_date] , :student_id => params[:student_id]}  )      	    
     end
    end

end
