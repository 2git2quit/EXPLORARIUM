class StaffsController < ApplicationController
  # GET /staffs
  # GET /staffs.json
  def index
    @staffs = Staff.all
    setStatus
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @staffs }
    end
  end

  # GET /staffs/1
  # GET /staffs/1.json
  def show
    @staff = Staff.find(params[:id])
    setStatus
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @staff }
    end
  end

  # GET /staffs/new
  # GET /staffs/new.json
  def new
    @staff = Staff.new
    setStatus
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @staff }
    end
  end

  # GET /staffs/1/edit
  def edit
    @staff = Staff.find(params[:id])
    @clockin = Clockin.find(:all,:conditions => ["staff_id=? and Date(time_in) = ? ",params[:id].to_i,Time.now.strftime('%Y-%m-%d')])
     setStatus
  end

  # POST /staffs
  # POST /staffs.json
  
    def create
    @staff = Staff.new(params[:staff])
    encrypted_password= Digest::SHA1.hexdigest(params[:staff][:password])
    @staff.password = encrypted_password
    respond_to do |format|
      if @staff.save
      	 @staffs = Staff.find(:all)
      	 setStatus
        format.html {render :action => "index"}
      else
        @validates = Array.new
        @staff.errors.messages.each do |m|
       	    @validates << m    
        end
        setStatus
        format.html { render :action => "new" }
        format.json { render :json => @staff.errors, :status => :unprocessable_entity }
      end
    end
  end


  # PUT /staffs/1
  # PUT /staffs/1.json
  def update
    @staff = Staff.find(params[:id])
    encrypted_password= Digest::SHA1.hexdigest(params[:staff][:password])
    @staff.password = encrypted_password

    respond_to do |format|
      if @staff.update_attributes(params[:staff])
      	@staffs = Staff.find(:all)
      	setStatus
        format.html {render :action => "index"}
      else
      	setStatus
        @validates = Array.new
        @staff.errors.messages.each do |m|
       	    @validates << m    
        end      	
        format.html { render :action => "edit" }
        format.json { render :json => @staff.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  

  # DELETE /staffs/1
  # DELETE /staffs/1.json
  def destroy
    @staff = Staff.find(params[:id])
    @staff.destroy

    respond_to do |format|
      format.html { redirect_to staffs_url }
      format.json { head :no_content }
    end
  end
  
  def setStatus
    @status = Array.new
    @status << {:id=>0,:name=>'Active'}
    @status << {:id=>1,:name=>'Inactive'}
  end  	  

  def timeclock
      @staffs = Staff.order(:lastname,:firstname).find(:all)
      render "timeclock" , :layout => "staff"
  end

  def clock_in
    
    msg = ""
    encrypted_password= Digest::SHA1.hexdigest(params[:password])
    s = Staff.find(:first,:conditions => ["id = ? and password = ?",params[:id],encrypted_password])
    unless s.nil?
      c = Clockin.find(:first,:conditions => ["staff_id=? and Date(time_in) = ? and time_out is null",params[:id].to_i,Time.now.strftime('%Y-%m-%d')])
      if (c.nil?)
        c = Clockin.new
        c.time_in = DateTime.now
        msg = "#{s.firstname} #{s.lastname} has clocked IN"
      else
        puts "<<< c : #{c.inspect}"
        c.time_out = DateTime.now
        msg = "#{s.firstname} #{s.lastname} has clocked OUT"
      end
      c.staff_id = s.id
      c.save
    else  
      msg = "Invalid Login ID or Password"
    end
    render :update do |page|
        page.replace_html("clocked" , :partial => "/staffs/clockedin"  , :locals => {:msg => msg})            
    end
 
  end
end
