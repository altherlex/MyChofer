class PaymentsController < ApplicationController
	layout "profile"
	before_filter :authenticate_user!
	skip_before_filter :verify_authenticity_token, :only => [:update, :create, :destroy, :index]
	
  #TODO: Continuar com o metodo de altera��o do cartao
  def update
  	raise 'k'
  end
  def index
		@cartaoes = SoapConnection::Cartao.lst_cliente(id_user).sort_by(&:preferencia).sort_by(&:tipo)
	end
	def create
		#Validacoes
		#lst_cartao = SoapConnection::Cartao.lst_cliente(id_user)
		#1. O Cliente n�o pode ter mais de um cartao perferencial ou secundario
		#if lst_cartao.detect(&:preferencia).present?
		#	flash[:notice] = 'N�o � poss�vel ter mais de um cart�o preferencial'
		#	render :edit
		#end
		# Just Test
		result=SoapConnection::Cartao.insert(id_user, params[:dta_vencimento], params[:nme_cartao], params[:cdg_bandeira_cartao], params[:nmr_cartao], params[:cdg_seguranca], params[:tpo_preferencia], params[:cdg_tipo])
		if result.map(&:cdg_forma_pagamento).compact.present?
			msg = "N�o foi poss�vel criar! [WS]Retorno:#{result[0].params_retorno}"
		else
			msg = "Sucesso!... [WS]Retorno:#{result[0].params_retorno}"
		end
		redirect_to '/payments', :flash=>{ :info => msg }
	end
	def destroy
		#if SoapConnection::Cartao.destroy(id_user, params[:id]).params_retorno
			redirect_to '/payments', :flash=>{ :info => "Cart�o exclu�do com sucesso!#{SoapConnection::Cartao.destroy(id_user, params[:id]).params_retorno}" }
		#else
		#	redirect_to '/payments', :flash=>{ :info => "Problema ao excluir o cart�o!" }
		#end
	end
	def id_user
		current_user.id rescue 1
	end
end
