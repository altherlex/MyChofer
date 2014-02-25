require 'savon'
require 'savon'
require 'aes'
require 'nokogiri'
require 'ostruct'
#require 'Iconv'

module SoapConnection
	class Service
		@@iv_const  = "y\xF1\n\x01\x84J\v'\xFF[-N\x0E\xD3\x16>"
		@@key_const = "d(*Mu96p@lg91?%0c*f7&d^`pk?ly$f7"
		@@aes_type  = "AES-256-CBC"
		@@dev_token = "dyciamxnrqedr6xojgjwrss2"

		NAMESPACES = {
			"xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/",
			"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
			"xmlns:xsd" => "http://www.w3.org/2001/XMLSchema"
		}
		DATE_AND_TIME_NO_ZONE='%Y-%m-%dT%H:%M:%S'

		attr_accessor :method_name, :method_name_camel, :client, :response, :decrypted, :result
		def initialize(p_method_name)
			if p_method_name.to_s.include?('_') #p_method_name em underscore
				self.method_name = p_method_name
				self.method_name_camel = p_method_name.to_s.camelcase
			else #p_method_name Camelcase
				self.method_name = p_method_name.to_s.underscore
				self.method_name_camel = p_method_name.to_s
			end
			self.client = Savon::Client.new{ wsdl.document = "http://www.santacruzsistemas.com.br/WS/Service.asmx?WSDL"}
		end
		def invoke(*params)
			#params.map!(&:to_s)
			Rails.logger.info	"#{'*'*60}Invoking WS#{'*'*60}"
			Rails.logger.info "Metodo chamado: #{self.method_name_camel}"
			Rails.logger.info "parametros: #{params.inspect}"

			puts	"#{'*'*60}Invoking WS#{'*'*60}"
			puts "Metodo chamado: #{self.method_name_camel}"
			puts "parametros: #{params.inspect}"

			@response=self.client.request(self.method_name_camel) do
				http.headers["SOAPAction"] = "http://tempuri.org/#{self.method_name_camel}"
				soap.xml do |xml|
					xml.soap(:Envelope, NAMESPACES) do |xml|
						Service.define_head(xml)
						xml.soap(:Body) do |xml|
							# Para metodos do WS que pede parametros
							if params.present?
								eval %{
									xml.#{self.method_name_camel}(:xmlns=>"http://tempuri.org/") do |x|
										x.strparms( "#{Service.encrypt_values(params)}" )
									end
								}
							else
								xml.send(self.method_name_camel, :xmlns=> "http://tempuri.org/")
							end
						end
					end
				end
			end
			begin
				@decrypted=Service.decrypt_with_response(@response,@method_name)
				@result=Service.higienize(@decrypted)
				@result = @result.to_a[0][1] rescue @result
			rescue => e
				Rails.logger.info	"#{e.message} \n #{e.backtrace}"
				@result=@response
			end
			Rails.logger.info "result: #{@result.inspect}"
			Rails.logger.info "#{'*'*60}Finished WS#{'*'*60}"

			puts "result: #{@result.inspect}"
			puts "#{'*'*60}Finished WS#{'*'*60}"
			return @result
		end
		class << self
			def decrypt_with_response( p_response, p_method_name )
				method_name_response = "#{p_method_name}_response"
				method_name_result   = "#{p_method_name}_result"
				#aes init com o tipo AES-256-CBC
				aes = OpenSSL::Cipher::Cipher.new(@@aes_type)
				#no caso do ruby, precisa chamar o método encrypt ou decrypt antes de qualquer outra coisa.
				aes.decrypt
				#setar key
				aes.key = @@key_const
				#setar iv
				aes.iv = @@iv_const
				#decodificar o resultado encriptado do request
				decoded64 = Base64.decode64(p_response.to_hash[method_name_response.to_sym][method_name_result.to_sym])
				#métodos do aes-ruby para realizar a decodificação
				result_ascii = aes.update(decoded64) + aes.final
			end
			def encrypt_values( *p_values )
				p_values = p_values.flatten
				#aes init com o tipo AES-256-CBC
				aes = OpenSSL::Cipher::Cipher.new(@@aes_type)
				#no caso do ruby, precisa chamar o método encrypt ou decrypt antes de qualquer outra coisa.
				aes.encrypt
				#setar key
				aes.key = @@key_const
				#setar iv
				aes.iv = @@iv_const
				result = aes.update(p_values.join('|')) + aes.final
				Base64.encode64(result)
			end
			def setar_atributos_com_hash( p_hash_cliente )
				return nil if !p_hash_cliente
				p_hash_cliente['Resultado']
			end
			def higienize(result)
				hash = Hash.from_xml(result) rescue result
				setar_atributos_com_hash( hash )
			end
			def define_head(xml)
				xml.soap(:Header) do |xml|
					xml.ValidationSoapHeader(:xmlns=>"http://tempuri.org/"){|xml| xml.DevToken(@@dev_token)}
				end
			end
		end # method class
	end # class Service

	class Cliente < Service
		#InsereRespostaCliente(cdg_corrida, resposta_cliente)
		#resposta_cliente = Chegou em 5 min("2") ou Estou indo("1")
		#AQUI
		def motorista_chamando(cdg_corrida, resposta_cliente)
			new('InsereRespostaCliente').invoke([cdg_corrida, resposta_cliente].map(&:to_s))
		end
		def self.insere_lista_convite(p_cdg_cliente, p_email, p_msg = 'Dear Fulano, precisa colocar essa mensagem no I18n')
			p=p_cdg_cliente,p_email,p_msg
			params = new(:insere_lista_convite).invoke(*p.map(&:to_s))
		end

		def self.chofer_user_status( p_cliente )
			p_cdg_cliente = p_cliente.cdg_id
			# apenas para teste
			p_cdg_cliente = 1
			hash = new(:consulta_mts_min_cliente).invoke(p_cdg_cliente.to_s)

			if hash["CodRetorno"] == "false"
				return nil
			end

			if p_cliente.class.to_s == 'OpenStruct'
				p_cliente.tempo_corrida = hash['Tempo_x0020_Corrida']
				p_cliente.metros_rodados = hash['Metros_x0020_Rodados']
			end

			p_cliente
		end
		def self.inserir( p_nome, p_sobrenome, p_email, p_telefone, p_senha, foto_url )
			p = p_nome, p_sobrenome, p_email, p_telefone, p_senha, foto_url
			params=new(:insere_cliente).invoke( *p.map(&:to_s) )
			set_record(params)
		end
		def self.atualizar( p_id, p_nome, p_sobrenome, p_email, p_telefone, p_senha, foto_url )
			p=p_id, p_nome, p_sobrenome, p_email, p_telefone, p_senha, foto_url
			params=Service.new(:atualiza_cliente).invoke( p.map(&:to_s) )
			Cliente.set_record(params)
		end
		def self.lista
			new(:lista_clientes).invoke
		end
		def self.excluir(p_id)
			new(:exclui_cliente).invoke(p_id)
		end
		def self.login(email, senha)
			params=new('Login').invoke([email, senha].map(&:to_s))
			if params.is_a?Array
				params=params.first
			end
			return set_record(params)
		end
		def self.carregar(p_id)
			set_record Service.new('ConsultaCliente').invoke(p_id.to_s)
		end
		def self.set_record(p_hash)
			record = OpenStruct.new
			if p_hash["CodRetorno"]=="false"
				return nil
			else
				record.params_retorno=p_hash
				record.cdg_id=p_hash["A001_CD_CLIENTE"]
				record.id=p_hash["A001_CD_CLIENTE"]
				record.first_name=p_hash["A001_NOME"]
				record.last_name=p_hash["A001_SOBRENOME"]
				record.number_phone=p_hash["A001_TELEFONE"]
				record.password=p_hash["A001_SENHA"]
				record.email=p_hash["A001_EMAIL"]
				record.login=record.email
				puts p_hash["A001_FOTO_URL"].to_s
				record.imagem_url = p_hash["A001_FOTO_URL"]
				return record
			end
		end #set_record
	end

	class Cupom < Cliente
		def self.cupons(p_cdg_cliente)
			params=new(:consulta_cupom_cliente).invoke(*p_cdg_cliente )
			set_record(params)
		end

		def self.insere_cupom( p_cdg_cliente, p_cdg_cupom )
			p=p_cdg_cliente, p_cdg_cupom
			params=new(:insere_cupom_desconto).invoke(*p.map(&:to_s))

			if params.class.to_s == 'Hash'
				if params['CodRetorno'] == 'false'
					return false
				else
					return true
				end
			end
		end


		def self.set_record( p_hash )
			p_hash = [p_hash].flatten

			cupons = []

			if p_hash.class.to_s == 'Hash' && p_hash["CodRetorno"]=="false"
				return nil
			else
				p_hash.each do |hash|
					# CUPOM
					record = OpenStruct.new

					record.cdg_cliente 							=hash["A001_CD_CLIENTE"]
					record.cdg_id										=hash["A025_CD_CUPOM"]
					record.id												=hash["A025_CD_CUPOM"]
					record.valor										=hash["A025_VLR_CUPOM"]
					record.ind_excl_log							=hash["IND_EXCL_LOG"]
					record.indicador_utilizado 			=hash["A025_IND_UTILIZADO"]
					record.nome_cupom				  			=hash["A025_CD_CUPOM_GERADO"]
					record.processado								=hash["A025_IND_PROCESSADO"]
					record.tipo_cupom								=hash["A025_IND_TIPO_CUPOM"]
					cupons << record
				end
			end

			return cupons
		end
	end

	class Cidade < Service
		def self.atendidas
			arr = [new(:ListaCidadesAtendidas).invoke].flatten.map{|i| set_record(i)}.flatten.uniq

			arr2 = []


			# O WS nao trata as cidades repetidas.
			arr.each do |x|
				cidade_repetida = false

				arr2.each do |z|
					if z.cdg_cidade == x.cdg_cidade
						cidade_repetida = true
						break
					end
				end

				if	!cidade_repetida
					arr2 << x
				end
			end

			arr2
		end

		def self.set_record(p_hash)
			[p_hash].flatten.map do |i|
				record = OpenStruct.new
				record.nme_cidade = i['A907_NOME']
				record.cdg_cidade = i['A018_CD_CIDADE_ATENDIDA']
				record.sigla = i['A906_SIGLA']
				record.cdg_area_atuacao = i['A014_CD_AREA_ATUACAO']
				record
			end
		end
	end
	class ListaInteresse < Service
		def self.lst_tipo_poi
			convert_obj=lambda {|p_hash|
				record = OpenStruct.new
				record.cdg_tpo_poi = p_hash['A020_CD_TIPO_POI']
				record.nme_tpo_poi = p_hash['A020_NOME']
				record.ind_excl_log = p_hash['IND_EXCL_LOG']
				record.dta_inc_alt = p_hash['DTA_INC_ALT']
				return record
			}
			new(:ListaTipoPOI).invoke.map{|i| convert_obj.call(i)}
		end
		def self.lst_poi(cdg_cidade, cdg_tpo_poi)
			r=[new(:ListaPOI).invoke(*[cdg_cidade.to_s, cdg_tpo_poi.to_s])].flatten
			set_record(r)
		end
		#ARR_CIDADES_ATENDIDAS = SoapConnection::Cidade.atendidas
		#ARR_TIPO_POI = lst_tipo_poi.uniq.freeze
		def self.lst_poi_all
			arr_param=[]
			SoapConnection::Cidade.atendidas.each do |cidade|
				lst_tipo_poi.uniq.each do |tipo_poi|
					lst_poi(cidade.cdg_cidade,tipo_poi.cdg_tpo_poi).each do |p_arr|
						result=set_record(p_arr)
						result.map!{|i|
							i.nme_cidade=cidade.nme_cidade.titleize
							i.nme_tpo_poi=tipo_poi.nme_tpo_poi.titleize
							i
						}
						arr_param<<result
					end
				end
			end
			return arr_param.flatten.uniq_by(&:cdg_poi)
		end
		def self.lst_poi_all_group_to_select
			lst_poi_all.group_by(&:nme_cidade).map{|i, v| [i, v.map{|a| ["#{a.nme_local}(#{a.nme_tpo_poi})", a.cdg_poi, {:lat_lng=>a.lat_lng_localizacao}]}]}
		end
		def self.set_record(p_arr)
			p_arr = [p_arr].flatten
			p_arr.map{|p_hash|
				record = OpenStruct.new
				record.retorno=p_hash["CodRetorno"]
				record.lat_lng_localizacao=p_hash["A021_LOCALIZACAO"]
				record.nme_local=p_hash["A021_NOME"].titleize rescue ''
				record.cdg_poi=p_hash["A021_CD_POI"]
				record.dta_alteracao=p_hash["DTA_INC_ALT"]
				record.cdg_tpo_poi=p_hash["A020_CD_TIPO_POI"]
				record.cdg_cidade=p_hash["A018_CD_CIDADE_ATENDIDA"]
				record.ind_excl_log=p_hash["IND_EXCL_LOG"]
				record
			}
		end
	end

	class Corrida < Service
		def self.lista_pacotes(p_cdg_cidade_atendida)
			params = new(:lista_pacotes).invoke(*p_cdg_cidade_atendida.to_s)
			set_pacote_record(params)
		end

		def self.set_pacote_record(p_hash)
=begin
- A022_VALOR: "400"
  A022_HORAS: "4"
  A022_NOME: 4 HORAS
  IND_EXCL_LOG: N
  A018_CD_CIDADE_ATENDIDA: "1"
  A022_FRANQUIA_DIST: "400000"
  DTA_INC_ALT: "2012-08-16T00:00:00-03:00"
  A022_FRANQUIA_TMP: "240"
  A022_CD_PACOTE: "1"
=end
			p_hash = [p_hash].flatten
			cupons = []
			if p_hash.class.to_s == 'Hash' && p_hash["CodRetorno"]=="false"
				return nil
			else
				p_hash.each do |hash|
					# CUPOM
					record = OpenStruct.new
					record.id									=hash["A022_CD_PACOTE"]
					record.cdg_id							=hash["A022_CD_PACOTE"]
					record.valor 							=hash["A022_VALOR"]
					record.horas							=hash["A022_HORAS"]
					record.nome								=hash["A022_NOME"]
					record.valor							=hash["A025_VLR_CUPOM"]
					record.cdg_cidade					=hash["A018_CD_CIDADE_ATENDIDA"]
					record.franquia_dist			=hash["A022_FRANQUIA_DIST"]
					record.cdg_cidade					=hash["A018_CD_CIDADE_ATENDIDA"]
					record.franquia_tmp				=hash["A022_FRANQUIA_TMP"]
					record.tpo_carro 					=hash["A032_CD_TIPO_VEICULO"]
					cupons << record
				end
			end
			return cupons
		end

		def self.preco_corrida(p_cdg_corrida)
			params = new(:preco_corrida).invoke(*p_cdg_corrida.to_s)
			set_preco_record(params)
		end

		def self.set_preco_record(p_hash)
			if p_hash['CodRetorno'] == 'false'
				return nil
			end
			record = OpenStruct.new
			record.valor_real 		= p_hash['A026_VLR_REAL']
			record.valor_estimado = p_hash['A026_VLR_ESTIMADO']
			return record
		end

=begin
	p_cdg_resposta = 0- Cliente não respondeu
	p_cdg_resposta = 1 - Cliente está vindo
	p_cdg_resposta = 2 - Cliente irá em 5 minutos
=end
		def self.insere_resposta_cliente( p_cdg_corrida, p_cdg_resposta )
			new(:insere_resposta_cliente).invoke(*[p_cdg_corrida, p_cdg_resposta].map(&:to_s))
		end

		def self.insere_rating_motorista(p_cdg_motorista, p_pontos)
			p=p_cdg_motorista, p_pontos
			params = new(:insere_rating_motorista).invoke(*p.map(&:to_s))
			puts params.to_yaml
		end

		def self.lista_em_aberto
			new(:lista_corridas_aberto).invoke
		end
		# ListaCorridasAbertoCliente
		def self.corridas_aberto_cliente(cdg_cliente_solicitante)
			r=[new(:lista_corridas_aberto_cliente).invoke(*cdg_cliente_solicitante.to_s)].flatten
			r.map!{|param| set_record(param)}
			r.map!{|i| (i.retorno=='false')? nil : i }
			# Ordenado por dta da corrida
			#FIXME: Este método deveria trazer apenas as corridas ativas! Por isso o select
			#Apenas corridas agendadas e ativas
			return r.compact.select{|i| I18n.td_arr('corrida.regra.status_pendentes').include?(i.status_corrida)}.sort_by(&:dta_corrida).reverse
		end
		# ConsultaCorridaCliente
		def self.corridas_anteriores_cliente(cdg_cliente_solicitante)
			r=[new(:ConsultaCorridaCliente).invoke(*cdg_cliente_solicitante.to_s)].flatten
			r.map!{|param| set_record(param)}
			r.map!{|i| (i.retorno=='false')? nil : i }
			return r.compact.sort_by(&:dta_corrida).reverse
		end
		#	string ConsultaCorrida(string CodCorrida)
		def self.carregar(p_id, p_informacoes_complementares = true)
			r=new(:consulta_corrida).invoke(p_id.to_s)
			raise "Método ConsultaCorrida retornou um objeto inválido. Objeto do tipo #{r.class}" unless r.is_a?Hash
			set_record(r, p_informacoes_complementares)
		end
		# *ERRO*
		# Este metodo retorna dois registros com latitude e longitude.
		def self.ConsultaAreaAtuacao(p_latitude, p_longitude)
			new(:consulta_area_atuacao).invoke(*[p_latitude, p_longitude].map(&:to_s))
		end
=begin
Data e Hora | A gendado ou D epois | Código do Tipo de Carro 1 - Blind. 2 - Normal | Tipo de Corrida TU Trajeto Unico e PK Pacote | Codigo do Pacote 0 para nenhum ou o código do pacote (adquirido na chamada
) | Coordenadas da Origem | Coordenadas do Destino | Endereço de Origem | Endereçop de Destino | Kilometragem Estimada | Tempo Estimado | Valor Estimado | Código do Cliente Solicitante | Código do Cliente Atendido | Status da Corrida | Observações | Código do Ponto de Interesse Origem | Código do Ponto de Interesse Destino
#InsereCorrida(
	string Agenda,
	string TipoCarro ('N' Normal; 'B' Blindado)
	string TipoCorrida ("AT" Ativa, "FI" Finalizada, "CC" Cancelada Cliente, "CM" Cancelada Motorista, "AG" Agendada
	string CodPacote (????)
	string Origem (ex: "-23.576722,-46.645761")
	string Destino (ex: "-23.569996,-46.635354")
	string VlrEstimado (???? Acredito q sera feito outra requisicao para WS para recuprar o valor aproximado=> method ConsultaTarifas return "Failed to convert parameter value from a String to a Int32.")
	string CodClienteSolicitante, (CodClienteAtendido é igual ao CodClienteSolicitante se a corrida é 'pra mim')
	string CodClienteAtendido,
	string KmRodadoEstimado,
	string TmpCorridaEstimado (tempo estimado em minutos do percurso )
)
=end
=begin
		Parametros:
		 String HoraCorrida, String AgendaCorrida, string CodTipoCarro, string TipoCorrida, string CodPacote, string Origem,
		 string Destino, string OrigemEndereco, string DestinoEndereco, string KmRodadoEstimado, string TmpCorridaEstimado,
		 string VlrEstimado, string CodClienteSolicitante, string CodClienteAtendido, string StatusCorrida, string Observacao, string CodPOIOrigem, string CodPOIDestino
=end
		CDG_POI_ORIGEM='0'
		CDG_POI_DESTINO='0'
		# !O WebService atualiza o status da corrida!
		# Status da Corrida
		# CC - Cancelada pelo cliente
		# CM - cancelada pelo motorista
    # CS - cancelada pelo sistema
		# AT - ativa
		# AM - Aguardando motorista
		# AG - Agendada
		# FI - Finalizada
		STATUS_CORRIDA=' '
		AGENDA_CORRIDA='A'
		CDG_TPO_CARRO='1' #Normal
		CDG_PACOTE='0'
		#dta_corrida,
		#agenda_corrida = 'A' agora; 'D' Depois
		#cdg_tpo_carro ('1' Normal; '2' Blindado)
		#tpo_corrida,
		#cdg_pacote ?????
		#lat_log_origem,
		#lat_log_destino,
		#dsc_endereco_origem,
		#dsc_endereco_destino,
		#km_rodado_estimado,
		#min_estimado_corrida,
		#vlr_estimado,
		#cdg_cliente_solicitante
		#-- Insere corrida
		def self.insere(
								dta_corrida, #"2012-07-31 19:33:53"
								lat_log_origem, #"-23.576722,-46.645761"
								lat_log_destino, #"-23.544986,-46.539845"
								dsc_endereco_origem, #"R. Tomás Carvalhal, 480 - Vila Mariana São Paulo, 04006-001"
								dsc_endereco_destino, #"R. Odete Gomes Barreto, 255 - Carrão São Paulo, 03441-010"
								qtd_metros_estimado, #164 metros
								qtd_minutos_estimado, #26 min
								cdg_cliente_solicitante,
								vlr_estimado, #10.50
								cdg_tpo_carro,
								cdg_poi_origem,
								cdg_poi_destino,
								agenda_corrida,
								cdg_pacote,
								cdg_cliente_atendido,
								cdg_cidade_atendida,
								observacao)



			# Se o preco estimado da corrida nao retornar nada será finalizado a inserção de corrida sem notificação!
			return false unless vlr_estimado.present?

			# TPO_CORRIDA: PK || TU
			if cdg_pacote.to_s=='0'
				tpo_corrida='TU' #Trajeto Unico
			else
				tpo_corrida='PK' #Pacote
			end

			status_corrida=STATUS_CORRIDA

			arr_params = dta_corrida, agenda_corrida, (cdg_tpo_carro||CDG_TPO_CARRO), tpo_corrida, cdg_pacote, lat_log_origem, lat_log_destino, dsc_endereco_origem, dsc_endereco_destino, qtd_metros_estimado, qtd_minutos_estimado, vlr_estimado, cdg_cliente_solicitante, cdg_cliente_atendido, status_corrida, observacao, (cdg_poi_origem||CDG_POI_ORIGEM), (cdg_poi_destino||CDG_POI_DESTINO), cdg_cidade_atendida
			set_record( new(:insere_corrida).invoke(*arr_params.map!(&:to_s)) )
		end
		def self.cancela(p_cdg_corrida)
			new(:cancela_corrida_cliente).invoke(p_cdg_corrida)
		end

		DATE_AND_TIME='%Y-%m-%dT%H:%M:%S%Z'
		def self.set_record(p_hash, p_informacoes_complementares = true)
#Parametros possiveis: ["A026_DTA_ACEITE_CORRIDA", "A026_TMP_ESPERA", "A026_DESTINO", "A032_CD_TIPO_VEICULO", "A026_DTA_NO_SHOW", "A026_ALOJAMENTO", "A026_TMP_CORRIDA_REAL", "A026_VLR_REAL", "A026_VLR_REFEICAO", "A026_DESTINO_ENDERECO", "A026_OBSERVACOES", "A026_M_RODADO_REAL", "A026_CD_CORRIDA", "A026_DTA_PLAY_CORRIDA", "A026_ORIGEM_ENDERECO", "A026_VLR_ESTIMADO", "A026_VLR_ESTACIONAMENTO", "A026_VLR_PEDAGIO", "A026_TMP_CORRIDA_ESTIMADO", "A026_TIPO_CORRIDA", "A026_AGENDA_CORRIDA", "A001_CD_CLIENTE_SOLICITANTE", "A026_DTA_CHECKIN_MOTORISTA", "A001_CD_CLIENTE_ATENDIDO", "A026_DTA_SOL_CORRIDA", "A026_DTA_FIM_CORRIDA", "A026_DTA_INI_CORRIDA", "A010_CD_MOTORISTA", "A026_ORIGEM", "A026_M_RODADO_ESTIMADO", "A026_STATUS_CORRIDA", "A026_HORA_CORRIDA", "DTA_INC_ALT", "IND_EXCL_LOG"]
			record = OpenStruct.new
			record.retorno 											=p_hash["CodRetorno"]||p_hash["ConsultaTransaco"]
			record.consulta_transacao						=p_hash["ConsultaTransaco"]
			record.params_retorno 							=p_hash
			record.agenda_corrida								=p_hash["A026_AGENDA_CORRIDA"]
			record.tmp_corrida_real							=p_hash["A026_TMP_CORRIDA_REAL"]
			#Cliente solicitante: É o usuário logado no portal
			record.cdg_cliente_solicitante			=p_hash["A001_CD_CLIENTE_SOLICITANTE"]
			#Terceiro que usufrue do serviço
			record.cdg_cliente_atendido					=p_hash["A001_CD_CLIENTE_ATENDIDO"]
			# Carregar info do solicitante se for para terceiro
			if !record.cdg_cliente_solicitante.nil? and !record.cdg_cliente_atendido.nil? and record.cdg_cliente_solicitante!=record.cdg_cliente_atendido
				record.ClienteAtendido = Cliente.carregar(record.cdg_cliente_atendido)
			end
			record.cdg_corrida									=p_hash["A026_CD_CORRIDA"]
			record.status_corrida								=p_hash["A026_STATUS_CORRIDA"]
			record.vlr_estimado									=p_hash["A026_VLR_ESTIMADO"]
			record.m_rodado_estimado						=p_hash["A026_M_RODADO_ESTIMADO"]
			record.cdg_motorista								=p_hash["A010_CD_MOTORISTA"]
			# Carregar motorista
			if record.cdg_motorista && p_informacoes_complementares
				h_motorista=SoapConnection::Service.new('ConsultaMotorista').invoke(record.cdg_motorista.to_s)
				motorista = OpenStruct.new
				motorista.email = h_motorista["A010_EMAIL"]
				motorista.foto_url = h_motorista["A010_FOTO_URL"]
				motorista.nome = h_motorista["A010_NOME"]
				motorista.telefone = h_motorista["A010_TELEFONE"]
				motorista.cdg_motorista = h_motorista["A010_CD_MOTORISTA"]
				motorista.sobrenome = h_motorista["A010_SOBRENOME"]
				record.Motorista = motorista
			end
			if record.cdg_corrida && p_informacoes_complementares
				record.resposta_cliente_cru = SoapConnection::Service.new('ConsultaRespostaCliente').invoke(record.cdg_corrida.to_s)
				record.resposta_cliente = record.resposta_cliente_cru['CodRetorno'] rescue ''
			end
			record.origem												=p_hash["A026_ORIGEM"]
			record.destino											=p_hash["A026_DESTINO"]
			record.origem_endereco							=p_hash["A026_ORIGEM_ENDERECO"]
			record.destino_endereco							=p_hash["A026_DESTINO_ENDERECO"]
			record.hora_aviso_noshow						=p_hash["A030_HORA_AVISO_NOSHOW"]
			record.hora_aviso_cliente						=p_hash["A030_HORA_AVISO_CLIENTE"]
			record.vlr_real											=p_hash["A026_VLR_REAL"]
			record.hora_corrida									=p_hash["A026_HORA_CORRIDA"]
			record.dta_corrida									=DateTime.strptime(record.hora_corrida,DATE_AND_TIME) rescue nil
			record.tipo_corrida									=p_hash["A026_TIPO_CORRIDA"]
			record.hora_aviso_corrida_agendada	=p_hash["A030_HORA_AVISO_CORRIDA_AGENDADA"]
			record.m_rodado_real								=p_hash["A026_M_RODADO_REAL"]
			record.tmp_corrida_estimado					=p_hash["A026_TMP_CORRIDA_ESTIMADO"]
			#record.tipo_carro										=p_hash["A026_TIPO_CARRO"]
			record.tpo_veiculo									=p_hash["A032_CD_TIPO_VEICULO"]
			record.observacoes									=p_hash["A026_OBSERVACOES"]
			record.cdg_pacote										=p_hash["A022_CD_PACOTE"]
			if record.m_rodado_estimado && p_informacoes_complementares
				record.km_estimado = record.m_rodado_estimado.to_i/1000
			end
			if record.vlr_estimado && p_informacoes_complementares
				record.vlr_estimado_to_s='R$'+record.vlr_estimado.sub('.', ',')
			end
			return record
		end #set_record
	end #Corrida

	class Tarifa < Service
		#cdg_tpo_carro: 1=Normal; 2=Blindado
		def self.carregar(cdg_cidade, cdg_tpo_carro)
			new(:consulta_tarifas).invoke(cdg_cidade.to_s, cdg_tpo_carro.to_s)
		end
		# Default:
		#		tpo_carro = Normal (1)
		#		cdg_pacote = 0
		#		cdg_cidade = 1 #São Paulo
		def self.estimar_preco_da_corrida(cdg_cliente, qtd_min, qtd_metros, encodedPoints, tpo_carro, cdg_cidade, cdg_pacote, p_data_corrida)

#		def self.estimar_preco_da_corrida(cdg_cliente, qtd_min, qtd_metros, encodedPoints, tpo_carro=Corrida::CDG_TPO_CARRO, cdg_cidade=1, cdg_pacote=Corrida::CDG_PACOTE)
			#PrecoEstimado
			#	Params: codeClient, TimeEstimatedRun, KmEstimatedRun, codeCityServed, typeCar, encodedPoints, codePackage
			# ***CodPacote (Relacionado a uma promoção de pacotes de horas comprado pelo cliente)
			# Respostas
			#			{"VlrCupom"=>"0", "VlrEstimado"=>"115,15", "IndTipoCupom"=>"P"}: IndTipoCupom é P=porcentagem ou V=valor;
			#			[nil, {"CodRetorno"=>"false"}]

			params = cdg_cliente, qtd_min, qtd_metros, cdg_cidade, tpo_carro||Corrida::CDG_TPO_CARRO, encodedPoints, cdg_pacote, p_data_corrida
			set_record [new('PrecoEstimado').invoke(params.map!(&:to_s))]
		end

		def self.set_record(p_arr)
			r=[]
			p_arr.each{|p_hash|
				record 											= OpenStruct.new
				record.params_retorno				=p_hash
				record.vlr_estimado					=p_hash['VlrEstimado']
				record.vlr_estimado_formatado="R$#{record.vlr_estimado}"
				record.vlr_estimado_alt			=p_hash['VlrEstimado'].gsub(',','.')
				record.vlr_cupom 						= p_hash['VlrCupom']
				record.vlr_cupom_formatado	= "R$#{record.vlr_cupom}"
				record.ind_tpo_cupom 				= p_hash['IndTipoCupom']
				r<<record
			}
			return r
		end
		#ConsultaAreaAtuacao(string Latitude, string Longitude)
		# PRoblema neste metodo: Esta retornando dois registros, independente dos parametros passados
		def self.consulta_area_atuacao(latitude, longitude)
			params=latitude, longitude
			new(:consulta_area_atuacao).invoke(params.map!(&:to_s))
		end
	end
	class Cartao < Service
		def self.lista_detalhes_pagamento_cliente(cdg_cliente)
			new(:lista_detalhes_pagamento_cliente).invoke(*cdg_cliente.to_s)
		end
		def self.bandeiras
			new(:lista_bandeiras_cartao).invoke().map{|cartao| set_record(cartao) }
		end
		def self.bandeiras_to_options
			bandeiras.map{|i| [i.nome, i.cdg_bandeira]}
		end
=begin
		Params:CodCliente, CodCentroCusto, Tipo, Preferencia, DataVencimento, NomeCartao, UltimosDigitos, CodBandeira,NumCartao, CodSeguranca
		O que é...?
		CodCentroCusto: quando vc usa um cartão corporativo, todas as transações devem ser controladas por um centro de custo…. que pode ser por exemplo um departamento da emmpresa
			então…. no seu caso, vc deve tanto ter uma sessão para cadastrar o centro de custo, como uma para cadastrar o cartão (forma de pagamento)
		Tipo: 'P'Pessoal ou 'C'Corporativo
		Preferencia: "P" primário, "S" secundário ou "T" terciário
		DataVencimento (MM-yyyy)
		NomeCartao Nome do cliente (como está no cartão)
		UltimosDigitos: 4 últimos digitos do NumCartao
=end
		# TODO: Ver centro de custos
		DOMINIO_PREFERENCIA= eval I18n.t('dominio.cartao.preferencia')
		DOMINIO_TIPO=eval I18n.t('dominio.cartao.tipo')
		CDG_CENTRO_CUSTO=0 #Sem centro de custos
		TIPO='P'	#Pessoal
		PREFERENCIA='P' #Primario
		ULTIMOSDIGITOS=4
		def self.insert(cdg_cliente, dta_vencimento, nme_cartao, cdg_bandeira, nmr_cartao, cdg_seguranca, preferencia=PREFERENCIA, tipo=TIPO, cdg_centro_custo=CDG_CENTRO_CUSTO)
			nmr_cartao=nmr_cartao.to_s
			nmr_ultimos_digitos=nmr_cartao[(nmr_cartao.size-ULTIMOSDIGITOS)..-1]
			p=cdg_cliente, cdg_centro_custo, tipo, preferencia, dta_vencimento, nme_cartao, nmr_ultimos_digitos, cdg_bandeira, nmr_cartao, cdg_seguranca
			retorno=new('InsereDetalhesPagamentoCliente').invoke(*p.map(&:to_s))
			[retorno].flatten.compact.map{|c| set_record(c)}
		end
=begin
Bandeiras
	[["Visa", "1"], ["MASTERCARD", "2"], ["DINERS", "3"], ["AMEX", "4"]]
Cartão Teste
	Amex
		376411112222331
	Mastercard
		5555666677778884
		5453010000066167
	Diners
		30111122223331
	Visa
		4012001037141112 (com autenticação)
		4551870000000183 (sem autenticação)
=end
		def self.lst_cliente(cdg_cliente)
			r=[new('ListaDetalhesPagamentoCliente').invoke(cdg_cliente.to_s)].flatten.map{|cartao| set_record(cartao) }
			return [] if r.map(&:cdg_retorno).join=='0'
			return r
		end
		
		#TODO: Continuar com o metodo de alteração do cartao
		#def self.lst_cliente(cdg_cliente)
		#	AtualizaDetalhesPagamentoCliente
		#end
		
		#Excluindo cartao =>"1", "1", "0"
		#Excluindo Centro de custo =>"1", "0", "1"
		def self.destroy(cdg_cliente, cdg_cartao, cdg_centro_custo=CDG_CENTRO_CUSTO)
			set_record new('ExcluiDetalhesPagamentoCliente').invoke(*[cdg_cliente, cdg_cartao, cdg_centro_custo].map(&:to_s))#cdg_forma_pagamento
		end
		def self.set_record(p_hash)
			record = OpenStruct.new
			# to flags
			record.params_retorno	=p_hash
			record.cdg_retorno  	=p_hash['CodRetorno']
			record.nome					  =p_hash["A003_NOME"]
			record.ind_excl_log 	=p_hash["IND_EXCL_LOG"]
			record.dta_inc_alt  	=p_hash["DTA_INC_ALT"]
			record.cdg_bandeira 	=p_hash["A003_CD_BANDEIRA"]
			# to cards
			record.preferencia					=p_hash["A004_PREFERENCIA"] #S
			record.dsc_preferencia			=I18n.td('dominio.cartao.preferencia', record.preferencia)
			record.tipo 								=p_hash["A004_TIPO"] #P
			record.dsc_tipo 						=I18n.td('dominio.cartao.tipo',record.tipo);
			record.cdg_cliente				 	=p_hash["A001_CD_CLIENTE"] #1
			record.cdg_forma_pagamento	=p_hash["A004_CD_FORMA_PAGAMENTO"] #1
			record.dta_inc_alt 				 	=p_hash["DTA_INC_ALT"] #2012-08-13T15:10:27.44-03:00
			record.dta_alteracao				=DateTime.strptime(record.dta_inc_alt,DATE_AND_TIME_NO_ZONE) rescue nil
			record.cdg_cartao 					=p_hash["A002_CD_CARTAO"] #1
			record.ultimos_digitos			=p_hash["A002_ULTIMOS_DIGITOS"]
			return record
		end
	end

	class Empresa < Service
		def self.valida_master(cdg_cliente, user_object = nil)

			# user_object = usuÃ¡rio que irei adicionar o atributo usuario_master = true
			# Master poderÃ¡ fazer complementaÃ§Ã£o de informaÃ§Ãµes da empresa (Nem tudo, apenas os dados de contato, o resto deve ser travado na tela);
			hash = new(:valida_master).invoke(*cdg_cliente.to_s)

			if hash["CodRetorno"] == "false"
				return false
			end

			cdg_empresa = hash['A006_CD_EMPRESA_CLIENTE']

			if hash['A008_IND_MASTER'] == 'Y'
				user_object.is_master = true if user_object
			end

			empresa = nil

			if cdg_empresa.to_i != 0
				empresa = Cliente.carregar( cdg_empresa )
			end

			return empresa
		end

		def self.lista_empresa(p_cdg_empresa)
			r = new(:lista_empresa_cliente_empresa).invoke(*p_cdg_empresa.to_s)

			clientes = []

			if r.class.to_s != 'Array' && r['CodRetorno'] == 'false'
				return nil
			end

			r.each do |cliente|
				clientes << Cliente.carregar(cliente['A001_CD_CLIENTE'])
			end

			return clientes
		end

		def self.delete_cliente( p_cdg_empresa, p_cdg_cliente )
			p=p_cdg_empresa, p_cdg_cliente
			params=new(:delete_empresa_cliente_cliente).invoke( *p.map(&:to_s) )
			puts params.to_yaml
			set_record(params)
		end


		#verificar esses metodos
		def self.atualiza_empresa( p_cdg_empresa, p_nome, p_razao_social, p_cnpj, p_logradouro, p_nome_contato, p_cidade, p_email_contato, p_tel_comercial, p_tel_cel_contato )
			p=p_cdg_empresa, p_nome, p_razao_social, p_cnpj, p_logradouro, p_nome_contato, p_cidade, p_email_contato, p_tel_comercial, p_tel_cel_contato
			params=new(:atualiza_empresa_cliente).invoke( *p.map(&:to_s) )
			puts params.to_yaml
			set_record(params)
		end

		def self.insere_cliente( p_cdg_empresa, p_cdg_cliente, p_usuario_master )
			p=p_cdg_empresa, p_cdg_cliente, p_usuario_master
			params=new(:insere_empresa_cliente_cliente).invoke(*p.map(&:to_s))
		end

		def self.lista_corridas_empresa_cliente(p_cdg_cliente)
=begin
- A026_ORIGEM_ENDERECO: Rua TesteA
  A026_M_RODADO_ESTIMADO: "4000"
  A026_AGENDA_CORRIDA: A
  A026_ORIGEM: -23.585876,-46.601837
  A026_DESTINO_ENDERECO:
    __content__: " "
    xml:space: preserve
  IND_EXCL_LOG: N
  A026_STATUS_CORRIDA: CP
  A001_CD_CLIENTE_ATENDIDO: "1"
  DTA_INC_ALT: "2012-09-07T12:00:29.65-03:00"
  A026_VLR_REAL: "0.00"
  A032_CD_TIPO_VEICULO: "1"
  A026_TMP_CORRIDA_ESTIMADO: "240"
  A026_DTA_SOL_CORRIDA: "2012-09-07T12:00:29.65-03:00"
  A026_VLR_ESTIMADO: "400.25"
  A026_DESTINO:
    __content__: " "
    xml:space: preserve
  A022_CD_PACOTE: "1"
  A026_TIPO_CORRIDA: PK
  A001_CD_CLIENTE_SOLICITANTE: "1"
  A026_HORA_CORRIDA: "2012-07-31T19:33:00-03:00"
  A026_OBSERVACOES:
    __content__: " "
    xml:space: preserve
  A026_CD_CORRIDA: "1"
=end

			corridas = new(:consulta_corrida_cliente).invoke(*p_cdg_cliente.to_s)

			array_return = []

			if corridas.class.to_s == 'Array'
				corridas.each do |corrida|
					array_return << Corrida.set_record(corrida, false)
				end
			end

			return array_return
		end

		#Ver quem vai usar isso
		#Quem usar isso sÃ³ pode ser Master, verificar se essa validaÃ§Ã£o acontecerÃ¡ no inicio do login ou durante run
		def self.insere_centro_custo(cdg_interno, p_descricao)
			p=cdg_interno, p_descricao
			hash = new(:insere_centrode_custo).invoke(*p.map(&:to_s))

			#A005_CD_CENTRO_CUSTO"=>"2"

			# verificar o que fazer com esse codigo
			if hash
				return hash['A005_CD_CENTRO_CUSTO']
			end

			return false
		end

		def self.insere_centro_custo_empresa(p_cdg_empresa, p_cdg_centro_custo)
			p=p_cdg_empresa, p_cdg_centro_custo
			hash = new(:insere_empresa_cliente_centro_custo).invoke(*p.map(&:to_s))

			puts hash.to_yaml

			#Aguardando pq nao esta funcionando
			return false

			# verificar o que fazer com esse codigo
			if hash
				return hash['A005_CD_CENTRO_CUSTO']
			end

			return false
		end

		def self.insere_centro_de_custo_cliente(p_cdg_cliente, p_cdg_centro_custo, p_tipo, p_preferencia)
			p=p_cdg_cliente, p_cdg_centro_custo, p_tipo, p_preferencia
			hash = new(:insere_centrode_custo_cliente).invoke(*p.map(&:to_s))

			# verificar o que fazer com esse codigo
			if hash
				if hash["CodRetorno"] == "false"
					return false
				end

				#{"A004_CD_FORMA_PAGAMENTO"=>"12"}
				return hash['A004_CD_FORMA_PAGAMENTO']
			end

			return false
		end

		def self.delete_centro_de_custo_cliente(p_cdg_cliente, p_cdg_centro_custo)
			p=p_cdg_cliente, p_cdg_centro_custo
			hash = new(:delete_centrode_custo_cliente).invoke(*p.map(&:to_s))

			# verificar o que fazer com esse codigo
			if hash
				if hash["CodRetorno"] == "false"
					return false
				end

				# {"A004_CD_FORMA_PAGAMENTO"=>"12"}
				# return hash['A004_CD_FORMA_PAGAMENTO']
			end

			return false
		end

		def self.set_record(p_hash)
			record = OpenStruct.new

			if p_hash["CodRetorno"]=="false"
				return nil
			else
				#{"A001_TELEFONE"=>"88296448", "A001_EMAIL"=>"teste@gmail.com", "DTA_INC_ALT"=>"2012-08-21T20:48:16.22-03:00", "A001_SENHA"=>"123456789", "A001_LOGIN"=>"teste@gmail.com", "A001_NOME"=>"Testing", "A001_CD_CLIENTE"=>"44", "A001_SOBRENOME"=>"Testing", "IND_EXCL_LOG"=>"N"}
				record.cdg_id								=p_hash["A001_CD_CLIENTE"]
				record.id										=p_hash["A001_CD_CLIENTE"]
				record.first_name						=p_hash["A001_NOME"]
				record.last_name						=p_hash["A001_SOBRENOME"]
				record.number_phone					=p_hash["A001_TELEFONE"]
				record.password							=p_hash["A001_SENHA"]
				record.email								=p_hash["A001_EMAIL"]
				record.login								=record.email
				return record
			end
		end
	end

	class ChoferUsers < Service
		def self.users( cdg_cliente )
			p = new(:lista_empresa_cliente_empresa).invoke(*cdg_cliente.to_s)

			return false if p.class.to_s == 'Hash' && p['CodRetorno'] == 'false'

			users = []

			if p
				[p].flatten.each do |x|
					user = SoapConnection::Cliente.carregar( x['A001_CD_CLIENTE'] )
					users << user
				end
			end

			return users
		end

		def self.delete( p_cdg_empresa, p_cdg_cliente )
			p=p_cdg_empresa, p_cdg_cliente
			hash = new(:delete_empresa_cliente_cliente).invoke(*p.map(&:to_s))
		end

		#Deprecrate. Use da classe Cliente o metodo carregar
		#method ConsultaCliente
		def self.user_with_id( cdg_cliente )
			set_record(new(:consulta_cliente).invoke(*cdg_cliente.to_s))
		end

		def self.set_record(p_hash)
			record = OpenStruct.new
			if p_hash["CodRetorno"]=="false"
				return nil
			else
				#{"A001_TELEFONE"=>"88296448", "A001_EMAIL"=>"teste@gmail.com", "DTA_INC_ALT"=>"2012-08-21T20:48:16.22-03:00", "A001_SENHA"=>"123456789", "A001_LOGIN"=>"teste@gmail.com", "A001_NOME"=>"Testing", "A001_CD_CLIENTE"=>"44", "A001_SOBRENOME"=>"Testing", "IND_EXCL_LOG"=>"N"}
				record.cdg_id=p_hash["A001_CD_CLIENTE"]
				record.id=p_hash["A001_CD_CLIENTE"]
				record.first_name=p_hash["A001_NOME"]
				record.last_name=p_hash["A001_SOBRENOME"]
				record.number_phone=p_hash["A001_TELEFONE"]
				record.password=p_hash["A001_SENHA"]
				record.email=p_hash["A001_EMAIL"]
				record.login=record.email
				return record
			end
		end #set_record
	end

end