class MonthCoveredsController < ApplicationController
	
  # GET /month_covereds
  # GET /month_covereds.json
  def index
    @month_covereds = MonthCovered.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @month_covereds }
    end
  end

  # GET /month_covereds/1
  # GET /month_covereds/1.json
  def show
    @month_covered = MonthCovered.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @month_covered }
    end
  end

  # GET /month_covereds/new
  # GET /month_covereds/new.json
  def new
    @month_covered = MonthCovered.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @month_covered }
    end
  end

  # GET /month_covereds/1/edit
  def edit
    @month_covered = MonthCovered.find(params[:id])
  end

  # POST /month_covereds
  # POST /month_covereds.json
  def create
    @month_covered = MonthCovered.new(params[:month_covered])

    respond_to do |format|
      if @month_covered.save
        format.html { redirect_to @month_covered, :notice => 'Month covered was successfully created.' }
        format.json { render :json => @month_covered, :status => :created, :location => @month_covered }
      else
        format.html { render :action => "new" }
        format.json { render :json => @month_covered.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /month_covereds/1
  # PUT /month_covereds/1.json
  def update
    @month_covered = MonthCovered.find(params[:id])

    respond_to do |format|
      if @month_covered.update_attributes(params[:month_covered])
        format.html { redirect_to @month_covered, :notice => 'Month covered was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @month_covered.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /month_covereds/1
  # DELETE /month_covereds/1.json
  def destroy
    @month_covered = MonthCovered.find(params[:id])
    @month_covered.destroy

    respond_to do |format|
      format.html { redirect_to month_covereds_url }
      format.json { head :no_content }
    end
  end
end
