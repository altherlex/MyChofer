class ChoferUsersController < ApplicationController
	layout "profile"
	#before_filter :authenticate_user!
	#prepend_before_filter :authenticate_user!

  def index
		#  current_user.cdg_id
		@@users = SoapConnection::ChoferUsers.users( (1 rescue 1) ).compact rescue []
		@users = @@users
	end

	def new
		@edit	= false
	end

	def create
		nome 			= params[:first_name]
		sobrenome = params[:last_name]
		email 		= params[:email]
		telefone 	= params[:number_phone]
		senha 		= params[:email]
		foto 			= 'http://www.santacruzsistemas.com.br/Perfil/Cliente/defaultprofile.png'
		is_master = params[:is_master].to_i

		status = false

		usuario = SoapConnection::Cliente.inserir( nome, sobrenome, email, telefone, senha, foto )

		if usuario
			#cdg_empresa = current_user.empresa.cdg_id
			cdg_empresa = 1

			empresa = SoapConnection::Empresa.insere_cliente( cdg_empresa, usuario.cdg_id, (is_master == 1 ? 'Y' : 'N') )

			if empresa
				status = true
			end
		end

		if status
			redirect_to :action => 'index'
		else
			redirect_to :action => 'new'
		end
	end

	def edit
		@usuario = SoapConnection::Cliente.carregar(params[:id])

		if !@usuario
			redirect_to :action => 'index'
		end

		@edit = true
	end

	def load_journeys
		@corridas = SoapConnection::Empresa.lista_corridas_empresa_cliente( params[:id] )

		html = []

		html << "<table>"

		@corridas.each do |x|
		break
			html << "<tr>"
			html << "	<td>"
			html << "		destino #{x.destino}"
			html << "	</td>"
			html << "	</tr>"
		end

		html << "</table>"

		puts html.join.html_safe.to_s

@corridas = []

	  respond_to do |format|
        format.json { render :patial => 'corridas', :locals => nil}
    end

#		render :js do |page|
#			page.replace_html  "corridas_#{params[:id]}", :partial => 'corridas'#, :collection => @users
#			page.visual_effect :highlight, "corridas_#{params[:id]}"
#		end
	end

=begin
	def corridas
		@usuario = SoapConnection::Cliente.carregar(params[:id])

		if @usuario
			@usuario.corridas = SoapConnection::Empresa.lista_corridas_empresa_cliente( usuario.cdg_id )
		end

		raise @usuario.corridas.to_yaml
	end
=end

	def update
		raise 'update' + params.to_yaml
	end

	def destroy
		cdg_usuario = params[:id]

		cdg_empresa = current_user.empresa.cdg_id rescue 1
		cdg_empresa = 1

		SoapConnection::ChoferUsers.delete(cdg_empresa , cdg_usuario )

		redirect_to :action => 'index'
	end


end