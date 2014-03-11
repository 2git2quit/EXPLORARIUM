module UsersHelper
	def quarter(t=Time.now.strftime('%-m'))
  	  if (t > 0 && t< 4)
  	  	  return 'Q1'  
  	  elsif (t > 3 && t < 7)
  	  	  return 'Q2'  
  	  elsif (t > 6 && t < 10)
  	  	  return 'Q3'  
  	  elsif (t > 9)
  	  	  return 'Q4' 
  	  else
  	  	  return ''
  	  end
  end
end
