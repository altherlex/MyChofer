class RegistrationsController < Devise::RegistrationsController
	layout 'profile', :only => [:edit, :update]
	#def	create
	#	super
	#end
end