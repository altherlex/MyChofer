class ProfilesController < ApplicationController
	layout "profile"
	before_filter :authenticate_user!
  def invitations
  end
  
  def send_invites
		emails = params[:invite][:invite].split(';')
		message = params[:invite][:message]
		
		emails.each do |x|
			SoapConnection::Cliente.insere_lista_convite((current_user.id rescue 1), x, (message.to_s == '' ? nil : message))
		end
		
		redirect_to :action => 'invitations'
  end
	
#TODO: Enviar os convites pelo Devise
#	def send_invites
#		self.resource = resource_class.send_confirmation_instructions(resource_params)
#    if successfully_sent?(resource)
#      respond_with({}, :location => after_resending_confirmation_instructions_path_for(resource_name))
#    else
#      respond_with(resource)
#    end
#	end
	
=begin
class Devise::Mailer < ::ActionMailer::Base
  include Devise::Mailers::Helpers

  def confirmation_instructions(record)
    devise_mail(record, :confirmation_instructions)
  end

  def reset_password_instructions(record)
    devise_mail(record, :reset_password_instructions)
  end

  def unlock_instructions(record)
    devise_mail(record, :unlock_instructions)
  end
end
=end	
end
