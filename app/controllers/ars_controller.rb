class ArsController < ApplicationController
  # GET /ars
  # GET /ars.json
  def index
    @ars = Ar.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @ars }
    end
  end

  # GET /ars/1
  # GET /ars/1.json
  def show
    @ar = Ar.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @ar }
    end
  end

  # GET /ars/new
  # GET /ars/new.json
  def new
    @ar = Ar.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @ar }
    end
  end

  # GET /ars/1/edit
  def edit
    @ar = Ar.find(params[:id])
  end

  # POST /ars
  # POST /ars.json
  def create
    @ar = Ar.new(params[:ar])

    respond_to do |format|
      if @ar.save
        format.html { redirect_to @ar, :notice => 'Ar was successfully created.' }
        format.json { render :json => @ar, :status => :created, :location => @ar }
      else
        format.html { render :action => "new" }
        format.json { render :json => @ar.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /ars/1
  # PUT /ars/1.json
  def update
    @ar = Ar.find(params[:id])

    respond_to do |format|
      if @ar.update_attributes(params[:ar])
        format.html { redirect_to @ar, :notice => 'Ar was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @ar.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /ars/1
  # DELETE /ars/1.json
  def destroy
    @ar = Ar.find(params[:id])
    @ar.destroy

    respond_to do |format|
      format.html { redirect_to ars_url }
      format.json { head :no_content }
    end
  end
end
