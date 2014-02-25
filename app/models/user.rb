require "open-uri"
class User < ActiveRecord::Base
	around_save :create_or_insert_in_ws
	after_rollback :rollback_to_ws

	def avatar_absolute_url
		File.join(ActionController::Base.asset_host.to_s, self.avatar.url(:small))
	end

  	# Include default devise modules. Others available are:
  	# :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable,
   	:recoverable, :rememberable, :validatable
		#:token_authenticatable, :trackable, :confirmable

	# Setup accessible (or protected) attributes for your model
	attr_accessible :avatar, :first_name, :last_name, :number_phone, :idiom, :email, :senha, :password, :password_confirmation, :remember_me, :is_master, :empresa
	attr_accessor :cdg_id, :is_master, :empresa, :skip_callback_to_save

	has_attached_file :avatar,
		:styles => {:small => "80x80", :icon => "48x48"},
		:default_url => '/assets/profile/defaultprofile.png'

	def self.new_without_callback(p_args)
		obj=new(p_args)
		obj.skip_callback_to_save=true
		obj
	end

	def avatar_from_url(url)
	  extname = File.extname(url)
	  basename = File.basename(url, extname)
	  file = Tempfile.new([basename, extname])
	  file.binmode

	  open(URI.parse(url)) do |data|
	    file.write data.read
	  end
	  file.rewind
	 	self.avatar = file
	end
	def tem_empresa?
		true if self.empresa
	end

	def empresa=(p_empresa)
		@empresa=p_empresa
	end

	def empresa
		@empresa
	end

	def complete_name
		"#{self.first_name} #{self.last_name}"
	end
	def cdg_id=(p_id)
	puts self.new_record?.to_s
		User.update_all( "id=#{p_id}", "id=#{self.read_attribute('id')}" )
		self.id=p_id
	end
	def password=(p_senha)
		self.senha = p_senha
		super(p_senha)
	end

	private
	def rollback_to_ws
		if self.new_record? and (@retorno.cdg_id.present? rescue false)
			SoapConnection::Cliente.excluir(@retorno.cdg_id)
		end
	end
	def create_or_insert_in_ws
		return yield if self.skip_callback_to_save==true
		if self.new_record?
			@retorno = SoapConnection::Cliente.inserir( self.first_name, self.last_name, self.email, self.number_phone, self.senha, self.avatar_absolute_url )
			# Caso a resposta do WS seja false será cancelado a inserção do novo usuário
			if @retorno.nil?
				self.errors[:base]<< "(WS)Erro ao inserir um cliente. Retorno:#{@retorno.inspect}"
				return false
			end
			self.id = @retorno.cdg_id
		elsif self.first_name_changed? or self.last_name_changed? or self.number_phone_changed? or self.email_changed? or self.senha_changed? or self.encrypted_password_changed? or self.avatar_file_name_changed? or self.avatar_content_type_changed? or self.avatar_file_size_changed?
			@retorno = SoapConnection::Cliente.atualizar( self.id, self.first_name, self.last_name, self.email, self.number_phone, self.senha, self.avatar_absolute_url )
			if @retorno.nil?
				self.errors[:base]<<"(WS)Erro ao inserir um cliente. Retorno:#{@retorno.inspect}"
				return false
			end
		end
		return yield
	rescue=>e
		self.errors[:base]<< e.message.inspect+'---- Backtrace:'+e.backtrace.inspect
		return false
	end
end