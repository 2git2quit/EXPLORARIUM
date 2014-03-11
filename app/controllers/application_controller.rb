class ApplicationController < ActionController::Base
  protect_from_forgery
  
   def require_authentication
      if  (!session[:expires_at].nil?)
        time_left = (session[:expires_at] - Time.now).to_i	   
        puts "<< USER Expires in #{time_left} seconds "
      	if (time_left < 0)
      	   session[:username] = nil
           session[:protected_page]  = "/students"
        end
      end
      session[:protected_page] = nil
      session[:protected_page] = request.fullpath.nil? ? "/students" : request.fullpath
      puts "SESSION ::: #{session[:username].nil?}"
      unless session[:username].nil?
      	 return true
      end
      rescue_action_login()
  end

  def rescue_action_login
      session[:protected_page] = request.fullpath.nil? ? "/students" : request.fullpath
      respond_to do |format|
      	format.html{session[:protected_page] = request.fullpath; redirect_to("/login")}
        format.js{session[:protected_page] = root_path; render :text => login_path, :status => "403", :content_type => 'text/html'}
      end
    end

    def authenticated?
       #If we already have a valid user, then we are authenticated already
       return true unless session[:username].nil?
       return false
  end

  def audit_log(username,details)
  	  a = AuditLog.new
  	  a.log_date = Time.now
  	  a.username=username
  	  a.details=details	  
  	  a.save
  end
  
 
end
