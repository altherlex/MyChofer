class ApplicationController < ActionController::Base
	#helper :all
  protect_from_forgery
	before_filter :set_charset
  def set_charset
		headers["Content-Type"] = "text/html; charset=ISO-8859-1"
		ActionController::Base.asset_host="#{request.scheme}://#{request.host_with_port}#{request.script_name}"	
  end
	
	protected
	def after_sign_in_path_for(resource)
		if user_signed_in?
			#edit_user_registration_path
			journeys_path
		else
			root_path
		end
	end
end
