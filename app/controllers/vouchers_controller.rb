class VouchersController < ApplicationController
	layout "profile"

	def index
		@cupons = SoapConnection::Cupom.cupons( (1) )
	end
	
	def create
		SoapConnection::Cupom.insere_cupom((current_user.id rescue 1), params[:cdg_cupom])
		redirect_to :action => 'index'
	end
	
	def update
		raise 'update'
	end
end
