class LevelsController < ApplicationController
	before_filter :require_authentication
  # GET /levels
  # GET /levels.json
  def index
    @levels = Level.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @levels }
    end
  end

  # GET /levels/1
  # GET /levels/1.json
  def show
    @level = Level.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @level }
    end
  end

  # GET /levels/new
  # GET /levels/new.json
  def new
    @level = Level.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @level }
    end
  end

  # GET /levels/1/edit
  def edit
    @level = Level.find(params[:id])
  end

  # POST /levels
  # POST /levels.json
  def create
    @level = Level.new(params[:level])

    respond_to do |format|
      if @level.save
      	@levels = Level.find(:all)
        format.html {render :action => "index"}
     else
        @validates = Array.new
        @level.errors.messages.each do |m|
       	    @validates << m    
        end
        format.html { render :action => "new" }
        format.json { render :json => @level.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /levels/1
  # PUT /levels/1.json
  def update
    @level = Level.find(params[:id])

    respond_to do |format|
      if @level.update_attributes(params[:level])
      	@levels = Level.find(:all)
        format.html {render :action => "index"}
      else
        @validates = Array.new
        @level.errors.messages.each do |m|
       	    @validates << m    
        end
        format.html { render :action => "edit" }
        format.json { render :json => @level.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /levels/1
  # DELETE /levels/1.json
  def destroy
    @level = Level.find(params[:id])
    @level.destroy

    respond_to do |format|
      format.html { redirect_to levels_url }
      format.json { head :no_content }
    end
  end
end
