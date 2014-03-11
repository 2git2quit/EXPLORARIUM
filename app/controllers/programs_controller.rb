class ProgramsController < ApplicationController
	before_filter :require_authentication
  # GET /programs
  # GET /programs.json
  def index
    @programs = Program.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @programs }
    end
  end

  # GET /programs/1
  # GET /programs/1.json
  def show
    @program = Program.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @program }
    end
  end

  # GET /programs/new
  # GET /programs/new.json
  def new
    @program = Program.new
    @cycles = [[1, "Monthly"],[3,"Quarterly"],[6,"Half-year"] ,[365,"Daily"]]

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @program }
    end
  end

  # GET /programs/1/edit
  def edit
    @program = Program.find(params[:id])
    @levels = Level.find(:all)
    @staffs = Staff.find(:all)
    #@schedules = @program.schedules
    @cycles = [[1, "Monthly"],[3,"Quarterly"],[6,"Half-year"] ,[365,"Daily"]]
  end

  # POST /programs
  # POST /programs.json
  def create
    if (params[:program][:cycle].nil? || params[:program][:cycle].blank?) 
    	params[:program][:cycle] = 1
    end

    @program = Program.new(params[:program])
    respond_to do |format|
      if @program.save
        @programs = Program.find(:all)
        format.html {render :action => "index"}
      else
        @validates = Array.new
        @program.errors.messages.each do |m|
       	    @validates << m    
        end
        format.html { render :action => "new" }
        format.json { render :json => @program.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /programs/1
  # PUT /programs/1.json
  def update
    if (params[:program][:cycle].nil? || params[:program][:cycle].blank?) 
	params[:program][:cycle] = 1
    end
    @program = Program.find(params[:id])
    #s = params[:schedules]
    #@program.schedules = s

    respond_to do |format|
      if @program.update_attributes(params[:program])
        @programs = Program.find(:all)
        format.html {render :action => "index"}
      else
      	#@schedules = @program.schedules
        @validates = Array.new
        @program.errors.messages.each do |m|
       	    @validates << m    
        end
        format.html { render :action => "edit" }
        format.json { render :json => @program.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /programs/1
  # DELETE /programs/1.json
  def destroy
    @program = Program.find(params[:id])
    @program.destroy

    respond_to do |format|
      format.html { redirect_to programs_url }
      format.json { head :no_content }
    end
  end
end
