require "open-uri"
class SessionsController < Devise::SessionsController
	def create
		# Sincroniza o BD com o WS
		cliente = SoapConnection::Cliente.login(params[:user][:email], params[:user][:password])
		#user = warden.authenticate(auth_options)
		# O objeto existe no WebService - email e senha certos!
		if !cliente.nil?
			user = User.find_by_email_and_senha(params[:user][:email], params[:user][:password])
			#O objeto não existe no Devise
			if user.nil?
				cliente=SoapConnection::Cliente.carregar(cliente.cdg_id)
				p={:first_name=>cliente.first_name, :last_name=>cliente.last_name, :email => cliente.email, :number_phone => cliente.number_phone, :password => cliente.password, :id => cliente.cdg_id }
				u=User.new_without_callback(p)
				u.save
				u.avatar_from_url( cliente.params_retorno['A001_FOTO_URL'] )
				u.cdg_id=p[:id]
				u.save
			end
		end
		super
   end
end