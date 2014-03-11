class LeavesController < ApplicationController
  # GET /staffs
  # GET /staffs.json
  def index
    @leaves = Leave.all
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @leaves }
    end
  end


  # GET /staffs/new
  # GET /staffs/new.json
  def new
    @leave = Leave.new
    @staffs = Staff.order(:lastname,:firstname).find(:all)
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @leave}
    end
  end

  # GET /staffs/1/edit
  def edit
   @leave = Leave.find(params[:id])
    @staffs = Staff.order(:lastname,:firstname).find(:all)
  end

  # POST /staffs
  # POST /staffs.json
  
  def create
   @leave = Leave.new(params[:leave])
   respond_to do |format|
      if @leave.save
        @leaves = Leave.find(:all)
        format.html {render :action => "index"}
      else
        @validates = Array.new
        @leave.errors.messages.each do |m|
       	    @validates << m    
        end
        format.html { render :action => "new" }
        format.json { render :json => @leave.errors, :status => :unprocessable_entity }
      end
    end
  end


  # PUT /staffs/1
  # PUT /staffs/1.json
  def update
    @leave = Leave.find(params[:id])

    respond_to do |format|
      if @leave.update_attributes(params[:leave])
        @leaves = Leave.find(:all)
        format.html {render :action => "index"}
      else
        @validates = Array.new
        @leave.errors.messages.each do |m|
       	    @validates << m    
        end      	
        format.html { render :action => "edit" }
        format.json { render :json => @leave.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  

  # DELETE /staffs/1
  # DELETE /staffs/1.json
  def destroy
   @leave = Leave.find(params[:id])
   @leave.destroy

    respond_to do |format|
      format.html { redirect_to leaves_url }
      format.json { head :no_content }
    end
  end
  

end
