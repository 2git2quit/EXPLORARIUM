class StudentsController < ApplicationController
  before_filter :require_authentication , :except => [:validateName]
  # GET /students
  # GET /students.json
  def index
    @students = Student.all
    setStatus
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @students }
    end
  end

  # GET /students/1
  # GET /students/1.json
  def show
    Rails.logger.info("<<<<<<<<< ::: PARAMS #{params.inspect}")
     @student = Student.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @student }
    end
  end

  # GET /students/new
  # GET /students/new.json
  def new
    @student = Student.new
    @siblings = {"0" => Hash.new , "1" => Hash.new , "2" => Hash.new}
    @status = Array.new
    setStatus
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @student }
    end
  end

  # GET /students/1/edit
  def edit
    @student = Student.find(params[:id])
    @siblings = @student.siblings
    setStatus
  end

  # POST /students
  # POST /students.json
  def create
    @student = Student.new(params[:student])
    @student.siblings = params[:sibling]

    respond_to do |format|
      if @student.save
      	@students = Student.find(:all)
      	setStatus
        format.html {render :action => "index"}
      else
        @validates = Array.new
        @student.errors.messages.each do |m|
       	    @validates << m    
        end
        #@student = Student.new
        @siblings = {"0" => Hash.new , "1" => Hash.new , "2" => Hash.new}
        @status = Array.new
        setStatus
        format.html { render :action => "new" }
        format.json { render :json => @student.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /students/1
  # PUT /students/1.json
  def update
   
    @student = Student.find(params[:id])
  
    s = params[:sibling]
    @student.siblings = s

    respond_to do |format|
      if @student.update_attributes(params[:student])
      	@students = Student.find(:all)
      	setStatus
        format.html {render :action => "index"}
      else
        @siblings = @student.siblings
        setStatus
        @validates = Array.new
        @student.errors.messages.each do |m|
       	    @validates << m    
        end
    
        format.html { render :action => "edit" }
        format.json { render :json => @student.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /students/1
  # DELETE /students/1.json
  def destroy
    @student = Student.find(params[:id])
    @student.destroy

    respond_to do |format|
      format.html { redirect_to students_url }
      format.json { head :no_content }
    end
  end


   def validateName
    student = Student.find(:all, :conditions => "lastname  = '#{params[:lastname]}' and firstname = '#{params[:firstname]}'")

    if (student.blank?)
      err = ''
    else
       err = "WARNING: Duplicate name"
    end
      render :update do |page|
        page.replace_html("errormsg" , :partial => "/students/errormsg" , :locals => { :validation_error => err}  )            
      end
  end
  
  def print_form
  	  s = Student.find(params[:id])
  	  params[:student] = s
      render :update do |page|
      	      page.replace_html("preform" ,  :partial => "/students/word" ,  :locals => {:params => params}  )            
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
