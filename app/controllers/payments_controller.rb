class PaymentsController < ApplicationController
  before_filter :require_authentication
  # GET /payments
  # GET /payments.json
  def index
   @payments = Payment.order("created_at").find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @payments }
    end
  end

  # GET /payments/1cderiquito
  # GET /payments/1.json
  def show
    @payment = Payment.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @payment }
    end
  end

  # GET /payments/new
  # GET /payments/new.json
  def new
    @payment = Payment.new
    @students = Student.order("lastname").find(:all)
    @programs = Program.order("name").find(:all)
    @levels = Level.find(:all)
#    @status = ["OLD","NEW"]
    @month_covered = MonthCovered.new
    @payment_detail = PaymentDetail.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @payment }
    end
  end

  # GET /payments/1/edit
  def edit
    @payment = Payment.find(params[:id])
    @history = Payment.order("updated_at").find(:all, :conditions => "student_id  = #{@payment.student_id}")    
    @students = Student.order("lastname").find(:all)
    @programs = Program.order("name").find(:all)
    @levels = Level.find(:all)
    @payment_detail = PaymentDetail.find(:first, :conditions => "payment_id  = #{params[:id]}") 
    if @payment_detail.nil?
    	@payment_detail = PaymentDetail.new
    end
    #@status = ["OLD","NEW"]
  end
  
  def month_load
     unless params[:months].nil?
	     @months = Array.new()
	     i=0
             params[:months].each do |key,val|
	        @month_covered = MonthCovered.new()
	        val.each do |k,v|
	        @month_covered.payment_id = @payment.id
	        @month_covered.student_id = @payment.student_id
	        @month_covered.program_id = @payment.program_id
                  if k.eql? "month"
                    @month_covered.month = v
                  end
                  if k.eql? "year"
                    @month_covered.year = v
                  end
  	       end #val.each
               @months[i] = @month_covered
               i=i+1  	       
             end #params[:months].each
     end  
  end
  
  def month_save
	     params[:months].each do |key,val|
	        @month_covered = MonthCovered.new()
	        val.each do |k,v|
	        @month_covered.payment_id = @payment.id
	        @month_covered.student_id = @payment.student_id
	        @month_covered.program_id = @payment.program_id
                  if k.eql? "month"
                    @month_covered.month = v
                  end
                  if k.eql? "year"
                    @month_covered.year = v
                  end
  	       end #val.each
  	       @month_covered.save
             end #params[:months].each
  end
  
  # POST /payments
  # POST /payments.json 

  def create
   	  @payment = Payment.new(params[:payment])
   	  @payment_detail = Payment.new(params[:payment_detail])
   	  @payment.newfee = params[:payment][:newfee].to_i
   	  @payment.hours = params[:payment][:daycount].to_f
          @validation_error = validate_for_required_fields(params)
          if @validation_error.nil?
            if params[:override_reason].upcase.include?('RESER')	  
               @payment.reservation_fee = params[:payment][:amount_paid]
            end
            if params[:override_reason].upcase.include?('HOURLY')	  
               @payment.daily_rate = params[:payment][:amount_paid]
            end
            @payment.override_reason = params[:override_reason]
   	        save_stat = @payment.save 
            if save_stat && !params[:months].nil?
       	      month_save 	
            end # if save_stat
          end
          
       respond_to do |format|
       if (save_stat && @validation_error.nil?)
        audit_log(session[:username],"New payments ID:#{@payment.id}")
        @payments = Payment.find(:all)
        format.html {render :action => "index"}
       else
        @validates = Array.new
        @payment.errors.messages.each do |m|
       	    @validates << m    
        end
        
        @students = Student.order("lastname").find(:all)
        @programs = Program.order("name").find(:all)
        @levels = Level.find(:all)
        @month_covered = MonthCovered.new
        @payment_detail = PaymentDetail.new
        format.html { render :action => "new" }
          format.json { render :json => @payment.errors, :status => :unprocessable_entity }
        end
     end # respond
  end
  
  def update
       @payment = Payment.find(params[:id])
       
       @payment_detail = PaymentDetail.find(:first, :conditions => "payment_id = #{params[:id].to_i}")
       if @payment_detail.nil?
       	   @payment_detail = PaymentDetail.new
       	   @payment_detail.payment_id = params[:id]
       end
       @payment.newfee = params[:payment][:newfee].to_i
       @payment.hours = params[:payment][:daycount].to_f

       @validation_error = validate_for_required_fields(params)
       if @validation_error.nil?
         if params[:override_reason].upcase.include?('RESER')	  
               @payment.reservation_fee = params[:payment][:amount_paid]
         end
         @payment.override_reason = params[:override_reason]
         save_stat =  @payment.update_attributes(params[:payment])
         save_stat = save_stat && @payment_detail.update_attributes(params[:payment_detail])
         unless @payment.month_covered.nil?
           @payment.month_covered.each do |m|
             m.destroy  
           end
         end
         if save_stat && !params[:months].nil?
        	month_save 	
         end # if save_stat
       end  
      #@validation_error = validate_for_required_fields(params)
      respond_to do |format|
      if (save_stat && @validation_error.nil?)
      	audit_log(session[:username],"Edit payments ID:#{@payment.id}")
        @payments = Payment.find(:all)
        format.html {render :action => "index"}
      else
        @validates = Array.new
        @payment.errors.messages.each do |m|
       	    @validates << m    
      end
    #@payment = Payment.find(params[:id])
    @payment.amount_paid = params[:payment][:amount_paid].to_f
    @payment.newfee =  params[:payment][:newfee]
    @payment.start_date =  params[:payment][:start_date]
    @payment.valid_date =  params[:payment][:valid_date]
    @payment.newfee = params[:payment][:newfee].to_f
    @history = Payment.order("updated_at").find(:all, :conditions => "student_id  = #{@payment.student_id}")    
    @students = Student.order("lastname").find(:all)
    @programs = Program.order("name").find(:all)
    @levels = Level.find(:all)
    @payment_detail = PaymentDetail.find(:first, :conditions => "payment_id  = #{params[:id]}") 
    if @payment_detail.nil?
    	@payment_detail = PaymentDetail.new
    end
     	format.html { render :action => "edit" }
        format.json { render :json => @payment.errors, :status => :unprocessable_entity }
      end
    end
  end
  # DELETE /payments/1
  # DELETE /payments/1.json
  def destroy
    @payment = Payment.find(params[:id])
    @payment.destroy
    audit_log(session[:username],"Deleted payments ID:#{params[:id]}")
    MonthCovered.delete_all(["payment_id = ?",params[:id]])
    PaymentDetail.delete_all(["payment_id = ?",params[:id]])
    respond_to do |format|
      format.html { redirect_to payments_url }
      format.json { head :no_content }
    end
  end
  
  
  def validate_for_required_fields(params)
     if !params[:overriden].blank?
      	      return nil    
      end
      
      if (!params[:override_username].blank? && !params[:override_password].blank?)
      encrypted_password= Digest::SHA1.hexdigest(params[:override_password])
      found = User.find(:first, :conditions => ["username = ? and password = ? and role='MANAGEMENT'",params[:override_username],encrypted_password])
      if (found.nil? || found.blank?)
      	 audit_log(session[:username],"Failed attempt to override payments using user [#{params[:override_username]}] for payment ID:#{params[:id]} - Reason: [#{params[:override_reason]}]")
  	 return "Invalid User"
      end
    end  
    
    if params[:payment][:program_id].blank?
       return nil
    end
  
       # for warning messages
       #if (!params[:commit].eql? "Override Warning")
       #if (found.nil?)
       if (params[:payment][:newfee].blank? || params[:payment][:newfee].to_i == 0 ) 
          p = Program.find(:first,:conditions => ["id =  ? ",params[:payment][:program_id].to_i] )
          Rails.logger.info("<<<<<< DAYCOUNT :: #{params[:payment][:daycount].nil?}   :: #{params[:payment][:daycount].blank?}")
          factor = params[:payment][:daycount].nil? ? 1 : params[:payment][:daycount].to_i
          if (p.cost.to_i*factor != params[:payment][:amount_paid].to_i)
            if (found.nil?)
            	return "WARNING: Amount paid does not match Tuition fee cost. Cost should be #{p.cost}"
            else
            	ar = Ar.find(:first,:conditions => "student_id = #{params[:payment][:student_id].to_i} and program_id = #{params[:payment][:program_id].to_i} and level_id = #{params[:payment][:level_id].to_i} ")
            	if ar.nil?
            	  ar = Ar.new
              	  ar.student_id =  params[:payment][:student_id].to_i
              	  ar.program_id =  params[:payment][:program_id].to_i
              	  ar.level_id =  params[:payment][:level_id].to_i
                end
                ar.amount = p.cost.to_f - params[:payment][:amount_paid].to_i
                ar.save
                audit_log(session[:username],"Successfully overriden payments using user [#{params[:override_username]}] for payment ID:#{params[:id]} : COST=#{p.cost} / AMOUNT PAID=#{params[:payment][:amount_paid]}")
            end
          end
       elsif   (params[:payment][:amount_paid].blank?)
          p = Program.find(:first,:conditions => ["id =  ? ",params[:payment][:program_id].to_i] )
          total = p.new_student_fee.to_i
          input_total =  params[:payment][:newfee].to_i
          if (total  != input_total)
            if (found.nil?)
          	  return "WARNING: Registration fee does not match total cost. Total Cost should be #{total}" 	    
             else
            	ar = Ar.find(:first,:conditions => "student_id = #{params[:payment][:student_id].to_i} and program_id = #{params[:payment][:program_id].to_i} and level_id = #{params[:payment][:level_id].to_i} ")
            	if ar.nil?
            	  ar = Ar.new
              	  ar.student_id =  params[:payment][:student_id].to_i
              	  ar.program_id =  params[:payment][:program_id].to_i
              	  ar.level_id =  params[:payment][:level_id].to_i
                end
                ar.newfee = p.new_student_fee.to_i - params[:payment][:newfee].to_i
                ar.save
                audit_log(session[:username],"Successfully overriden payments using user [#{params[:override_username]}] for payment ID:#{params[:id]} : REG FEE=#{p.new_student_fee} / AMOUNT PAID=#{params[:payment][:newfee]}")
            end
          end
       else	       
          p = Program.find(:first,:conditions => ["id =  ? ",params[:payment][:program_id].to_i] )
          total = p.cost.to_i + p.new_student_fee.to_i
          input_total = params[:payment][:amount_paid].to_i + params[:payment][:newfee].to_i
          if (total  != input_total)
             if (found.nil?)
          	  return "WARNING: Amount paid + Registration fee does not match total cost. Total Cost should be #{total}" 	    
             else
            	ar = Ar.find(:first,:conditions => "student_id = #{params[:payment][:student_id].to_i} and program_id = #{params[:payment][:program_id].to_i} and level_id = #{params[:payment][:level_id].to_i} ")
            	if ar.nil?
            	  ar = Ar.new
              	  ar.student_id =  params[:payment][:student_id].to_i
              	  ar.program_id =  params[:payment][:program_id].to_i
              	  ar.level_id =  params[:payment][:level_id].to_i
                end
                ar.newfee = p.new_student_fee.to_i - params[:payment][:newfee].to_i
                ar.amount = p.cost.to_f - params[:payment][:amount_paid].to_i
                ar.save
                audit_log(session[:username],"Successfully overriden payments using user [#{params[:override_username]}] for payment ID:#{params[:id]} : REG FEE=#{p.new_student_fee} / AMOUNT PAID=#{params[:payment][:newfee]} ::: COST=#{p.cost} / AMOUNT PAID=#{params[:payment][:amount_paid]}")
            end

          end
       end
    #end   

    return nil
  end
  
  def history
    @history = Payment.order("payment_date").find(:all, :conditions => "student_id  = #{params[:student_id]}")
    render :update do |page|
        page.replace_html("payment_history" , :partial => "/payments/history" , :locals => {:history => @history}  )      	    
    end
  end
  
  def programfee
    program = Program.find(params[:program_id])
    tuitionfee = program.cost
    regfee = program.new_student_fee
    render :update do |page|
    	    page.replace_html("fee" , :partial => "/payments/fee" , :locals => {:fee => tuitionfee , :regfee => regfee , :cycle => program.cycle}  )      	    
    end
  end
  
  def validate
    p = Program.find(params[:program_id])
    unless p.nil?
      if ((params[:amount_paid].to_i > 0) && (p.cost.to_i != params[:amount_paid].to_i) )
         validation_error = "WARNING: Amount paid does not match program cost. Cost should be #{p.cost}"
      end
      if ((params[:newfee].to_i > 0) && (p.new_student_fee.to_i != params[:newfee].to_i) )
         validation_error = "#{@validation_error}<br>WARNING: Registration fee does not match total cost. Total Cost should be #{p.new_student_fee}" 	    
      end
      render :update do |page|
      	      page.replace_html("validation" , :partial => "/payments/validate" , :locals => {:validation_error => validation_error}  )    	    
      end
    end
  end

  def checkOverride
    if (!params[:username].blank? && !params[:password].blank?)
      encrypted_password= Digest::SHA1.hexdigest(params[:password])
      found = User.find(:first, :conditions => ["username = ? and password = ? and role='MANAGEMENT'",params[:username],encrypted_password])
      if found.nil?
      	 audit_log(session[:username],"Failed attempt to override payments using user [#{params[:username]}] for payment ID:#{params[:id]} - Reason: [#{params[:reason]}]")
  	 validation_error = "Username or Password is incorrect"
      end
      render :update do |page|
      	  page.replace_html("over" , :partial => "/payments/check_override" , :locals => {:validation_error => validation_error}  )    	    
      end
    end  
  end
  
  def show_details
     payments = Payment.order(:payment_date).find(:all,:conditions => ["student_id = ?",params[:student_id]] )
     student = Student.find(params[:student_id])
     render :update do |page|
      	      page.replace_html("details" ,  :partial => "/users/payment_details" , :locals => {:payments => payments , :student => student}  )            
      end
  end

  
  def reassign_to
     ids = params["ids"].split(',')
     ids.each do |id|
       attendance = Attendance.find(id.to_i)
       attendance.program_id = params[:program_id].to_i
       attendance.save
     end
     render :update do |page|
     	     page.replace_html("reassign" , number_with_precision(params[:hours].to_i, :precision => 2) || 0  )            
     end
  end

end
