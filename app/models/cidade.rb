class Cidade < SoapConnection
  attr_accessor :cidade_id, :nome, :estado_id, :atendida
	
	def initialize(id, nome, estado_id)
		#Struct.new(:cidade_id, :nome, :estado_id, :atendida)
		self.cidade_id = id
		self.nome = nome
		self.estado_id=estado_id
	end

  class << self
		def lista_cidades
			arr_cidade=[]
			SoapConnection.new(:lista_cidades).invoke.each{|c|
				arr_cidade<<Cidade.new(c["A907_CD_CIDADE"], c["A907_NOME"], c["A906_CD_ESTADO"])
			}
			return arr_cidade
		end

		def lista_cidades_atendidas
			SoapConnection.new(:lista_cidades_atendidas).invoke
		end
	end
end